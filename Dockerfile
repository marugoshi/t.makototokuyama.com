FROM golang:1.13.5-stretch

# Set env
ENV LANG C.UTF-8
ENV TZ Asia/Tokyo

# Set working directory
WORKDIR /go/src/github.com/marugoshi/t.makototokuyama.com

# Install Hugo from source
RUN mkdir ~/src \
    && cd ~/src \
    && git clone https://github.com/gohugoio/hugo.git \
    && cd hugo \
    && go install --tags extended

COPY . .
