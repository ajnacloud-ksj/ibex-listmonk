package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/textproto"
	"strings"

	"github.com/knadh/listmonk/internal/manager"
	"github.com/knadh/listmonk/models"
	"github.com/labstack/echo/v4"
)

// isBroadcastMessenger determines if a messenger is a broadcast type (sends once per channel)
// rather than subscriber-based (sends once per subscriber).
// In Listmonk architecture:
// - "email" messenger is subscriber-specific (SMTP)
// - All postback messengers (webhooks) are broadcast-type
func isBroadcastMessenger(messengerName string) bool {
	// Email messenger is always subscriber-specific
	// All other messengers (postback/webhook) are broadcast-type
	return messengerName != "email"
}

// SendTxMessage handles the sending of a transactional message.
func (a *App) SendTxMessage(c echo.Context) error {
	var m models.TxMessage

	// If it's a multipart form, there may be file attachments.
	if strings.HasPrefix(c.Request().Header.Get("Content-Type"), "multipart/form-data") {
		form, err := c.MultipartForm()
		if err != nil {
			return echo.NewHTTPError(http.StatusBadRequest,
				a.i18n.Ts("globals.messages.invalidFields", "name", err.Error()))
		}

		data, ok := form.Value["data"]
		if !ok || len(data) != 1 {
			return echo.NewHTTPError(http.StatusBadRequest, a.i18n.Ts("globals.messages.invalidFields", "name", "data"))
		}

		// Parse the JSON data.
		if err := json.Unmarshal([]byte(data[0]), &m); err != nil {
			return echo.NewHTTPError(http.StatusBadRequest,
				a.i18n.Ts("globals.messages.invalidFields", "name", fmt.Sprintf("data: %s", err.Error())))
		}

		// Attach files.
		for _, f := range form.File["file"] {
			file, err := f.Open()
			if err != nil {
				return echo.NewHTTPError(http.StatusInternalServerError,
					a.i18n.Ts("globals.messages.invalidFields", "name", fmt.Sprintf("file: %s", err.Error())))
			}
			defer file.Close()

			b, err := io.ReadAll(file)
			if err != nil {
				return echo.NewHTTPError(http.StatusInternalServerError,
					a.i18n.Ts("globals.messages.invalidFields", "name", fmt.Sprintf("file: %s", err.Error())))
			}

			m.Attachments = append(m.Attachments, models.Attachment{
				Name:    f.Filename,
				Header:  manager.MakeAttachmentHeader(f.Filename, "base64", f.Header.Get("Content-Type")),
				Content: b,
			})
		}

	} else if err := c.Bind(&m); err != nil {
		return err
	}

	// Validate fields.
	if r, err := a.validateTxMessage(m); err != nil {
		return err
	} else {
		m = r
	}

	// Get the cached tx template (skip if using channels API)
	var tpl *models.Template
	var err error
	if len(m.Channels) == 0 {
		// Only get global template for legacy API
		tpl, err = a.manager.GetTpl(m.TemplateID)
		if err != nil {
			return echo.NewHTTPError(http.StatusBadRequest,
				a.i18n.Ts("globals.messages.notFound", "name", fmt.Sprintf("template %d", m.TemplateID)))
		}
	}

	var (
		subscribers []models.Subscriber
		notFound    []string
	)

	// Handle different recipient targeting methods
	if len(m.ListIDs) > 0 {
		// Get all subscribers from the specified lists by ID (any subscription status)
		listSubs, _, er := a.core.QuerySubscribers("", "", m.ListIDs, "", "id", "asc", 0, 0)
		if er != nil {
			return echo.NewHTTPError(http.StatusBadRequest,
				a.i18n.Ts("globals.messages.errorFetching", "name", fmt.Sprintf("list %v subscribers", m.ListIDs)))
		}
		subscribers = append(subscribers, listSubs...)
	} else if len(m.ListNames) > 0 {
		// Get list IDs from names first, then get subscribers
		for _, listName := range m.ListNames {
			lists, _, er := a.core.QueryLists(listName, "", "", []string{}, "name", "asc", true, []int{}, 0, 1)
			if er != nil {
				return echo.NewHTTPError(http.StatusBadRequest,
					a.i18n.Ts("globals.messages.errorFetching", "name", fmt.Sprintf("list '%s'", listName)))
			}
			if len(lists) == 0 {
				notFound = append(notFound, fmt.Sprintf("List '%s' not found", listName))
				continue
			}
			// Get subscribers from this list
			listIDs := []int{lists[0].ID}
			listSubs, _, er := a.core.QuerySubscribers("", "", listIDs, "", "id", "asc", 0, 0)
			if er != nil {
				return echo.NewHTTPError(http.StatusBadRequest,
					a.i18n.Ts("globals.messages.errorFetching", "name", fmt.Sprintf("list '%s' subscribers", listName)))
			}
			subscribers = append(subscribers, listSubs...)
		}
	} else if len(m.SubscriberIDs) > 0 {
		// Get subscribers by IDs
		for _, id := range m.SubscriberIDs {
			sub, er := a.core.GetSubscriber(id, "", "")
			if er != nil {
				if e, ok := er.(*echo.HTTPError); ok && e.Code == http.StatusBadRequest {
					notFound = append(notFound, fmt.Sprintf("Subscriber ID %d not found", id))
					continue
				}
				return er
			}
			subscribers = append(subscribers, sub)
		}
	} else {
		// Get subscribers by emails
		for _, email := range m.SubscriberEmails {
			sub, er := a.core.GetSubscriber(0, "", email)
			if er != nil {
				if e, ok := er.(*echo.HTTPError); ok && e.Code == http.StatusBadRequest {
					notFound = append(notFound, fmt.Sprintf("Subscriber (%s) not found", email))
					continue
				}
				return er
			}
			subscribers = append(subscribers, sub)
		}
	}

	// Enhanced multi-channel support with channels API
	if len(m.Channels) > 0 {
		// Separate broadcast channels from subscriber-based channels
		var broadcastChannels []models.TxChannel
		var subscriberChannels []models.TxChannel

		for _, channel := range m.Channels {
			if isBroadcastMessenger(channel.Channel) {
				broadcastChannels = append(broadcastChannels, channel)
			} else {
				subscriberChannels = append(subscriberChannels, channel)
			}
		}

		// Send broadcast channels ONCE per channel (not per subscriber)
		for _, channel := range broadcastChannels {
			// Use first subscriber for template rendering (broadcast doesn't need subscriber-specific data)
			var renderSub models.Subscriber
			if len(subscribers) > 0 {
				renderSub = subscribers[0]
			} else {
				// Skip if no subscribers available for template rendering
				continue
			}

			// Get template for this specific channel
			channelTpl, err := a.manager.GetTpl(channel.TemplateID)
			if err != nil {
				a.log.Printf("error getting template %d for broadcast channel %s: %v", channel.TemplateID, channel.Channel, err)
				continue
			}

			// Create a copy of the message for this channel
			channelMsg := m
			if err := channelMsg.Render(renderSub, channelTpl); err != nil {
				a.log.Printf("error rendering template %d for broadcast channel %s: %v", channel.TemplateID, channel.Channel, err)
				continue
			}

			// Prepare the message for this broadcast channel
			msg := models.Message{
				Subscriber:  renderSub,
				To:          []string{renderSub.Email},
				From:        channelMsg.FromEmail,
				Subject:     channelMsg.Subject,
				ContentType: channelMsg.ContentType,
				Messenger:   channel.Channel,
				Body:        channelMsg.Body,
				Data:        channelMsg.Data,
			}

			// Override content if specified
			if channel.Content != "" {
				msg.Body = []byte(channel.Content)
			}

			// Copy attachments
			for _, attachment := range channelMsg.Attachments {
				msg.Attachments = append(msg.Attachments, models.Attachment{
					Name:    attachment.Name,
					Header:  attachment.Header,
					Content: attachment.Content,
				})
			}

			// Optional headers
			if len(channelMsg.Headers) != 0 {
				msg.Headers = make(textproto.MIMEHeader, len(channelMsg.Headers))
				for _, set := range channelMsg.Headers {
					for hdr, val := range set {
						msg.Headers.Add(hdr, val)
					}
				}
			}

			// Send the broadcast message ONCE
			if err := a.manager.PushMessage(msg); err != nil {
				a.log.Printf("error sending to broadcast channel %s: %v", channel.Channel, err)
			} else {
				a.log.Printf("successfully sent broadcast message to channel %s", channel.Channel)
			}
		}

		// Process subscriber-based channels (email, etc.) - existing per-subscriber logic
		for _, sub := range subscribers {
			for _, channel := range subscriberChannels {
				// Get template for this specific channel
				channelTpl, err := a.manager.GetTpl(channel.TemplateID)
				if err != nil {
					a.log.Printf("error getting template %d for channel %s: %v", channel.TemplateID, channel.Channel, err)
					continue
				}

				// Create a copy of the message for this channel
				channelMsg := m
				if err := channelMsg.Render(sub, channelTpl); err != nil {
					a.log.Printf("error rendering template %d for channel %s: %v", channel.TemplateID, channel.Channel, err)
					continue
				}

				// Prepare the message for this channel
				msg := models.Message{
					Subscriber:  sub,
					To:          []string{sub.Email},
					From:        channelMsg.FromEmail,
					Subject:     channelMsg.Subject,
					ContentType: channelMsg.ContentType,
					Messenger:   channel.Channel,
					Body:        channelMsg.Body,
					Data:        channelMsg.Data,
				}

				// Override content if specified
				if channel.Content != "" {
					msg.Body = []byte(channel.Content)
				}

				// Copy attachments
				for _, attachment := range channelMsg.Attachments {
					msg.Attachments = append(msg.Attachments, models.Attachment{
						Name:    attachment.Name,
						Header:  attachment.Header,
						Content: attachment.Content,
					})
				}

				// Optional headers
				if len(channelMsg.Headers) != 0 {
					msg.Headers = make(textproto.MIMEHeader, len(channelMsg.Headers))
					for _, set := range channelMsg.Headers {
						for hdr, val := range set {
							msg.Headers.Add(hdr, val)
						}
					}
				}

				// Send the message
				if err := a.manager.PushMessage(msg); err != nil {
					a.log.Printf("error sending to channel %s: %v", channel.Channel, err)
				}
			}
		}
	} else {
		// LEGACY: Use existing messenger logic (backward compatibility)
		// Process all subscribers with legacy single-channel messaging
		for _, sub := range subscribers {
			// Render the message (skip if using channels API, render per-channel instead)
			if err := m.Render(sub, tpl); err != nil {
				return echo.NewHTTPError(http.StatusBadRequest,
					a.i18n.Ts("globals.messages.errorFetching", "name"))
			}

			messengers := []string{}
			if len(m.Messengers) > 0 {
				messengers = m.Messengers
			} else if m.Messenger != "" {
				messengers = []string{m.Messenger}
			} else {
				messengers = []string{"email"}
			}

			// Send to all specified messengers
			for _, messenger := range messengers {
				// Prepare the final message for this messenger
				msg := models.Message{}
				msg.Subscriber = sub
				msg.To = []string{sub.Email}
				msg.From = m.FromEmail
				msg.Subject = m.Subject
				msg.ContentType = m.ContentType
				msg.Messenger = messenger
				msg.Body = m.Body
				for _, a := range m.Attachments {
					msg.Attachments = append(msg.Attachments, models.Attachment{
						Name:    a.Name,
						Header:  a.Header,
						Content: a.Content,
					})
				}

				// Optional headers.
				if len(m.Headers) != 0 {
					msg.Headers = make(textproto.MIMEHeader, len(m.Headers))
					for _, set := range m.Headers {
						for hdr, val := range set {
							msg.Headers.Add(hdr, val)
						}
					}
				}

				if err := a.manager.PushMessage(msg); err != nil {
					a.log.Printf("error sending message to %s (%s): %v", messenger, msg.Subject, err)
					// Continue with other messengers instead of failing completely
				}
			}
		}
	}

	if len(notFound) > 0 {
		return echo.NewHTTPError(http.StatusBadRequest, strings.Join(notFound, "; "))
	}

	return c.JSON(http.StatusOK, okResp{true})
}

// validateTxMessage validates the tx message fields.
func (a *App) validateTxMessage(m models.TxMessage) (models.TxMessage, error) {
	if len(m.SubscriberEmails) > 0 && m.SubscriberEmail != "" {
		return m, echo.NewHTTPError(http.StatusBadRequest,
			a.i18n.Ts("globals.messages.invalidFields", "name", "do not send `subscriber_email`"))
	}
	if len(m.SubscriberIDs) > 0 && m.SubscriberID != 0 {
		return m, echo.NewHTTPError(http.StatusBadRequest,
			a.i18n.Ts("globals.messages.invalidFields", "name", "do not send `subscriber_id`"))
	}

	if m.SubscriberEmail != "" {
		m.SubscriberEmails = append(m.SubscriberEmails, m.SubscriberEmail)
	}

	if m.SubscriberID != 0 {
		m.SubscriberIDs = append(m.SubscriberIDs, m.SubscriberID)
	}

	// Check that at least one recipient method is provided
	hasEmails := len(m.SubscriberEmails) > 0
	hasIDs := len(m.SubscriberIDs) > 0
	hasListIDs := len(m.ListIDs) > 0
	hasListNames := len(m.ListNames) > 0

	if !hasEmails && !hasIDs && !hasListIDs && !hasListNames {
		return m, echo.NewHTTPError(http.StatusBadRequest,
			a.i18n.Ts("globals.messages.invalidFields", "name", "send subscriber_emails OR subscriber_ids OR list_ids OR list_names"))
	}

	// Check that only one recipient method is used
	methodCount := 0
	if hasEmails {
		methodCount++
	}
	if hasIDs {
		methodCount++
	}
	if hasListIDs {
		methodCount++
	}
	if hasListNames {
		methodCount++
	}

	if methodCount > 1 {
		return m, echo.NewHTTPError(http.StatusBadRequest,
			a.i18n.Ts("globals.messages.invalidFields", "name", "send only ONE of: subscriber_emails OR subscriber_ids OR list_ids OR list_names"))
	}

	for n, email := range m.SubscriberEmails {
		if email != "" {
			em, err := a.importer.SanitizeEmail(email)
			if err != nil {
				return m, echo.NewHTTPError(http.StatusBadRequest, err.Error())
			}
			m.SubscriberEmails[n] = em
		}
	}

	if m.FromEmail == "" {
		m.FromEmail = a.cfg.FromEmail
	}

	if m.Messenger == "" {
		m.Messenger = emailMsgr
	} else if !a.manager.HasMessenger(m.Messenger) {
		return m, echo.NewHTTPError(http.StatusBadRequest, a.i18n.Ts("campaigns.fieldInvalidMessenger", "name", m.Messenger))
	}

	return m, nil
}
