# OmniCaller Server

Rust-based web server for OmniCaller application.

## Tech Stack

- **Axum** - Web framework
- **Tokio** - Async runtime
- **Tower** - Middleware
- **Serde** - Serialization/deserialization
- **Dotenvy** - Environment variable management
- **Anyhow** - Error handling

## Getting Started

### Prerequisites

- Rust 1.70+ 
- Cargo

### Installation

```bash
cargo build
```

### Environment Configuration

Create a `.env` file from the example:

```bash
cp .env.example .env
```

Edit `.env` with your configuration:

```env
# Server Configuration
SERVER_HOST=0.0.0.0
SERVER_PORT=3000

# Application Configuration
APP_ENV=development
LOG_LEVEL=info
```

**Environment Variables:**

| Variable | Description | Valid Values | Default |
|----------|-------------|--------------|---------|
| `SERVER_HOST` | Server bind address | Any valid IP/hostname | `0.0.0.0` |
| `SERVER_PORT` | Server port | 1-65535 | `3000` |
| `APP_ENV` | Application environment | `development`, `staging`, `production` | `development` |
| `LOG_LEVEL` | Logging level | `trace`, `debug`, `info`, `warn`, `error` | `info` |

The configuration is validated on startup and will fail if invalid values are provided.

### Running the Server

```bash
cargo run
```

Server will start on the configured address (default: `http://0.0.0.0:3000`)

### Development Mode

Run with hot-reload using cargo-watch:

```bash
cargo install cargo-watch
cargo watch -x run
```

## Code Formatting

Format code using rustfmt:

```bash
# Format all code
cargo fmt

# Check if code is formatted
cargo fmt -- --check
```

Configuration is in `rustfmt.toml`.

## Code Linting

Run clippy for code quality checks:

```bash
# Run clippy
cargo clippy

# Run clippy with all checks
cargo clippy -- -W clippy::all
```

## API Endpoints

### GET /
Root endpoint returning server info

**Response:**
```json
{
  "success": true,
  "data": "OmniCaller Server",
  "error": null
}
```

### GET /health
Health check endpoint with environment info

**Response:**
```json
{
  "status": "healthy",
  "message": "Server is running",
  "environment": "Development"
}
```

### POST /api/echo
Echo endpoint for testing

**Request Body:**
```json
{
  "message": "Hello"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Hello"
  },
  "error": null
}
```

## Testing

```bash
# Run tests
cargo test

# Run tests with output
cargo test -- --nocapture

# Run with coverage
cargo tarpaulin --out Html
```

## Building for Production

```bash
# Set production environment
export APP_ENV=production
export LOG_LEVEL=warn

# Build release binary
cargo build --release
```

The binary will be available at `target/release/omnicaller_server`

## Project Structure

```
server/
├── src/
│   ├── main.rs           # Application entry point
│   └── config.rs         # Configuration management
├── Cargo.toml            # Dependencies
├── rustfmt.toml          # Code formatting rules
├── .env.example          # Environment template
└── README.md             # This file
```

## Configuration Architecture

The server uses object-based configuration management:

- Environment variables are loaded and validated on startup
- Configuration is passed as immutable objects (not accessed via `env::var` in handlers)
- Validation ensures all required values are present and valid
- Type-safe enums for environment and log levels
- Comprehensive error messages for misconfiguration

Example usage in code:

```rust
// Load configuration
let config = Config::from_env()?;
config.validate()?;

// Use in handlers
async fn handler(config: Config) {
    println!("Running in {:?} mode", config.app.env);
}
```
