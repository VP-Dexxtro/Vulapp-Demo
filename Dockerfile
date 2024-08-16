# Stage 1: Build stage
FROM python:3.10-alpine3.18 AS build

# Install necessary build dependencies
RUN apk --no-cache add libxml2-dev libxslt-dev gcc python3 python3-dev py3-pip musl-dev linux-headers

# Upgrade pip and install pex
RUN python3 -m ensurepip --upgrade && python3 -m pip install pex~=2.1.47

# Create source directory and copy requirements.txt
RUN mkdir /source
COPY requirements.txt /source/

# Build the pex wrapper
RUN pex -r /source/requirements.txt -o /source/pex_wrapper

# Stage 2: Final stage
FROM python:3.10-alpine3.18 AS final

# Upgrade the base image
RUN apk upgrade --no-cache

# Set working directory and create user
WORKDIR /dsvw
RUN adduser -D dsvw && chown -R dsvw:dsvw /dsvw

# Copy the application and pex wrapper
COPY dsvw.py .
RUN sed -i 's/127.0.0.1/0.0.0.0/g' dsvw.py
COPY --from=build /source/pex_wrapper /dsvw/pex_wrapper

# Expose the port
EXPOSE 65412

# Switch to non-root user
USER dsvw

# Run the script in the background and keep the container alive
CMD ["/bin/sh", "-c", "/dsvw/pex_wrapper dsvw.py & tail -f /dev/null"]
