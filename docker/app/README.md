# Docker Application

This directory contains Docker-related files for the DevOps Interview Assignment.

## Files

- **docker-compose.yml**: Local development setup using `nginxdemos/hello` image
- **README.md**: This documentation file

## Usage

### Local Development
```bash
# Run with nginxdemos/hello image
docker-compose up
```

### Production
The production deployment uses the `nginxdemos/hello` image directly as configured in the CloudFormation template.

## Notes

- The `nginxdemos/hello` image provides a simple "Hello World" web page
- No custom files are needed as we use the official demo image
- Production deployment uses the official demo image for simplicity and reliability
