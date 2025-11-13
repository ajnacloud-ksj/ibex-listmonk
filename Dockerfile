FROM alpine:latest

# Install dependencies
RUN apk --no-cache add ca-certificates tzdata shadow su-exec

# Set the working directory
WORKDIR /listmonk

# Copy only the necessary files
COPY listmonk .
COPY config.toml.sample config.toml.sample

# Copy required static assets (queries, schema, i18n, static)
COPY queries.sql .
COPY schema.sql .
COPY i18n/ ./i18n/
COPY static/ ./static/

# Copy the scripts directory
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

# Copy the entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/

# Make the entrypoint script executable
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose the application port
EXPOSE 9000

# Set the entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]

# Define the command to run the application
CMD ["./listmonk"]
