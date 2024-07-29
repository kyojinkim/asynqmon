#
# First stage: 
# Building.
#

FROM golang:1.22.5 AS builder

# Update and upgrade packages.
RUN apt update && apt -y upgrade

# https://stackoverflow.com/questions/69692842/error-message-error0308010cdigital-envelope-routinesunsupported
ENV NODE_OPTIONS=--openssl-legacy-provider
# Install npm (with latest nodejs) and yarn (globally, in silent mode).
RUN apt install -y nodejs npm && \
    npm i -g -s --unsafe-perm yarn

# Copy only ./ui folder to the working directory.
COPY ui .

# Run yarn scripts (install & build).
RUN yarn install && yarn build

# Move to a working directory (/build).
WORKDIR /build

# Copy and download dependencies.
COPY go.mod go.sum ./
RUN go mod download

# Copy a source code to the container.
COPY . .

# Set necessary environmet variables needed for the image and build the server.
ENV CGO_ENABLED=0 GOOS=linux

# Run go build (with ldflags to reduce binary size).
RUN go build -ldflags="-s -w" -o asynqmon ./cmd/asynqmon

#
# Second stage: 
# Creating and running a new scratch container with the backend binary.
#

FROM scratch

# Copy binary from /build to the root folder of the scratch container.
COPY --from=builder ["/build/asynqmon", "/"]
COPY --from=builder ["/build/ui/build", "/ui/build"]

# Command to run when starting the container.
ENTRYPOINT ["/asynqmon"]
