# API Contract Documentation

This document describes the expected API contract between DLAuthManager and your REST API backend.

## HTTP Headers

All requests automatically include:
- `Content-Type: application/json`
- `Authorization: Bearer {access_token}` (when `requiresAuth: true`)

## JSON Encoding/Decoding

- Request keys use `snake_case` (automatically converted from camelCase)
- Response keys use `snake_case` (automatically converted to camelCase)
- Dates use ISO 8601 format

## Endpoints

### 1. Sign Up
**Default Path:** `POST /auth/signup`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "metadata": {
    "firstName": "John",
    "lastName": "Doe"
  }
}
```

**Success Response (200):**
```json
{
  "user": {
    "id": "user-uuid",
    "email": "user@example.com",
    "phone": null,
    "email_confirmed_at": "2024-01-01T00:00:00Z",
    "phone_confirmed_at": null,
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z",
    "metadata": {
      "firstName": "John",
      "lastName": "Doe"
    }
  },
  "session": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "v1.MflBfPtHQzmXk...",
    "expires_in": 3600,
    "expires_at": "2024-01-01T01:00:00Z",
    "token_type": "Bearer"
  }
}
```

### 2. Sign In
**Default Path:** `POST /auth/signin`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Success Response (200):**
Same as Sign Up response

### 3. Sign Out
**Default Path:** `POST /auth/signout`

**Headers:** Requires `Authorization: Bearer {access_token}`

**Request Body:** Empty

**Success Response (200):**
Empty or:
```json
{
  "message": "Successfully signed out"
}
```

### 4. Get Current User
**Default Path:** `GET /auth/user`

**Headers:** Requires `Authorization: Bearer {access_token}`

**Success Response (200):**
```json
{
  "id": "user-uuid",
  "email": "user@example.com",
  "phone": null,
  "email_confirmed_at": "2024-01-01T00:00:00Z",
  "phone_confirmed_at": null,
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z",
  "metadata": {
    "firstName": "John",
    "lastName": "Doe"
  }
}
```

### 5. Resend OTP
**Default Path:** `POST /auth/otp/resend`

**Request Body:**
```json
{
  "email": "user@example.com",
  "type": "email"
}
```

**OTP Types:**
- `"signup"` - Signup verification
- `"email"` - Email verification
- `"sms"` - SMS verification
- `"phone_change"` - Phone number change
- `"email_change"` - Email change
- `"recovery"` - Account recovery

**Success Response (200):**
```json
{
  "message": "OTP sent successfully"
}
```

### 6. Verify OTP
**Default Path:** `POST /auth/otp/verify`

**Request Body:**
```json
{
  "email": "user@example.com",
  "token": "123456",
  "type": "email"
}
```

**Success Response (200):**
Same as Sign Up/Sign In response

### 7. Forgot Password
**Default Path:** `POST /auth/password/forgot`

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Success Response (200):**
```json
{
  "message": "Password reset email sent"
}
```

### 8. Reset Password
**Default Path:** `POST /auth/password/reset`

**Request Body:**
```json
{
  "token": "reset-token-from-email",
  "new_password": "newSecurePassword123"
}
```

**Success Response (200):**
Same as Sign Up/Sign In response

### 9. Update Password
**Default Path:** `PUT /auth/password/update`

**Headers:** Requires `Authorization: Bearer {access_token}`

**Request Body:**
```json
{
  "new_password": "newPassword123"
}
```

**Success Response (200):**
Same as Sign Up/Sign In response

### 10. Refresh Session
**Default Path:** `POST /auth/token/refresh`

**Request Body:**
```json
{
  "refresh_token": "v1.MflBfPtHQzmXk..."
}
```

**Success Response (200):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "v1.NewRefreshToken...",
  "expires_in": 3600,
  "expires_at": "2024-01-01T01:00:00Z",
  "token_type": "Bearer",
  "user": {
    "id": "user-uuid",
    "email": "user@example.com",
    ...
  }
}
```

## Error Responses

All error responses should use appropriate HTTP status codes and return:

```json
{
  "error": "Error type",
  "message": "Human-readable error message"
}
```

or

```json
{
  "message": "Human-readable error message"
}
```

### Common Status Codes

- `200` - Success
- `201` - Created (optional for sign up)
- `400` - Bad Request (validation errors)
- `401` - Unauthorized (invalid credentials, expired token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found (user not found)
- `422` - Unprocessable Entity (validation errors)
- `500` - Internal Server Error

### Error Response Examples

**Invalid Credentials (401):**
```json
{
  "error": "invalid_credentials",
  "message": "Invalid email or password"
}
```

**Token Expired (401):**
```json
{
  "error": "token_expired",
  "message": "Access token has expired"
}
```

**Validation Error (400):**
```json
{
  "error": "validation_error",
  "message": "Email is required"
}
```

## Customizing API Paths

You can customize all endpoint paths when initializing DLAuthManager:

```swift
let customPaths = DLAuthAPIPaths(
    signUp: "/api/v1/auth/register",
    signIn: "/api/v1/auth/login",
    signOut: "/api/v1/auth/logout",
    user: "/api/v1/auth/me",
    resendOTP: "/api/v1/auth/otp/resend",
    verifyOTP: "/api/v1/auth/otp/verify",
    forgotPassword: "/api/v1/auth/password/forgot",
    resetPassword: "/api/v1/auth/password/reset",
    updatePassword: "/api/v1/auth/password/update",
    refreshSession: "/api/v1/auth/token/refresh"
)

let apiURL = URL(string: "https://api.example.com")!
let authManager = DLAuthManager(url: apiURL, apiPaths: customPaths)
```

## Implementation Tips

1. **Session Storage**: Sessions are automatically stored in the iOS Keychain and persist across app launches

2. **Automatic Token Injection**: Access tokens are automatically added to request headers when `requiresAuth: true`

3. **Error Handling**: All methods throw `DLAuthError` which includes:
   - `invalidURL`
   - `invalidResponse`
   - `unauthorized`
   - `networkError(Error)`
   - `decodingError(Error)`
   - `serverError(statusCode: Int, message: String?)`
   - `noSession`
   - `invalidCredentials`
   - `userNotFound`
   - `tokenExpired`
   - `invalidToken`
   - `custom(String)`

4. **Date Handling**: All dates should be in ISO 8601 format (`2024-01-01T00:00:00Z`)

5. **Metadata**: The `metadata` field accepts any JSON-serializable data using the `AnyCodable` type

## Backend Implementation Examples

### Node.js/Express Example

```javascript
app.post('/auth/signup', async (req, res) => {
  const { email, password, metadata } = req.body;

  // Your signup logic here
  const user = await createUser(email, password, metadata);
  const session = await createSession(user);

  res.json({
    user: {
      id: user.id,
      email: user.email,
      email_confirmed_at: user.emailConfirmedAt,
      created_at: user.createdAt,
      updated_at: user.updatedAt,
      metadata: user.metadata
    },
    session: {
      access_token: session.accessToken,
      refresh_token: session.refreshToken,
      expires_in: 3600,
      expires_at: session.expiresAt,
      token_type: 'Bearer'
    }
  });
});
```

### Python/Flask Example

```python
@app.route('/auth/signin', methods=['POST'])
def signin():
    data = request.json
    email = data['email']
    password = data['password']

    # Your signin logic here
    user = authenticate_user(email, password)
    session = create_session(user)

    return jsonify({
        'user': {
            'id': user.id,
            'email': user.email,
            'email_confirmed_at': user.email_confirmed_at.isoformat(),
            'created_at': user.created_at.isoformat(),
            'updated_at': user.updated_at.isoformat(),
            'metadata': user.metadata
        },
        'session': {
            'access_token': session.access_token,
            'refresh_token': session.refresh_token,
            'expires_in': 3600,
            'expires_at': session.expires_at.isoformat(),
            'token_type': 'Bearer'
        }
    })
```

## Security Recommendations

1. **HTTPS Only**: Always use HTTPS in production
2. **Token Expiry**: Set reasonable expiration times for access tokens (15-60 minutes)
3. **Refresh Tokens**: Implement secure refresh token rotation
4. **Rate Limiting**: Implement rate limiting on authentication endpoints
5. **Password Requirements**: Enforce strong password requirements on the backend
6. **Email Verification**: Consider requiring email verification before full access
7. **Secure Token Storage**: Tokens are automatically stored in iOS Keychain by DLAuthManager
