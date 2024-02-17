# Use an official Telegraf base image
FROM telegraf:latest

# Set the working directory to Telegraf's configuration directory
WORKDIR /etc/telegraf

# Copy the Telegraf configuration file
COPY telegraf.conf /etc/telegraf/telegraf.conf

# Copy the custom plugin directory
COPY plugins/ /etc/telegraf/plugins/

# Compile the custom plugin, if necessary
# RUN go build -o /etc/telegraf/plugins/meter_ftp_input /etc/telegraf/plugins/meter_ftp_input.go

# Run Telegraf
CMD ["telegraf"]
