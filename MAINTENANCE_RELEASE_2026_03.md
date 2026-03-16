# Maintenance Release - March 2026

## Security Fixes

### 1. ReDoS and Regex Injection in Case-Insensitive Header Lookup

**Severity:** HIGH
**File:** `lib/reel/request/info.rb`
**Commit:** ea68104

**Vulnerability:** The `CASE_INSENSITVE_HASH` used raw string interpolation into a regex pattern for header key lookups (`/#{key}/i`), allowing attackers to inject arbitrary regex via header key access:
- `headers[".*"]` matched any header (wildcard injection)
- `headers["Content-Type|Authorization"]` matched multiple unintended headers
- Pathological patterns like `(a+)+$` could cause ReDoS

**Fix:** Replaced regex interpolation with `String#downcase` comparison. Also fixed the typo in the constant name (`INSENSITVE` -> `INSENSITIVE`).

**Tests:** `spec/reel/request_info_spec.rb` — 6 tests

---

### 2. HTTP Response Splitting (CRLF Injection) in Header Values

**Severity:** HIGH
**Files:** `lib/reel/response.rb`, `lib/reel/response/writer.rb`
**Commit:** 5a10f27

**Vulnerability:** Response header values were written to the socket without sanitizing CR/LF characters, allowing HTTP response splitting attacks when application code passes user-controlled data into response headers.

**Fix:** Defense-in-depth sanitization at two layers:
1. `Response` constructor: strips `\r` and `\n` from header values before `HTTP::Headers.coerce`
2. `Response::Writer#render_header`: sanitizes at write time as a secondary guard

**Tests:** `spec/reel/response/writer_crlf_injection_spec.rb` — 7 tests

---

### 3. User Input in Error Messages (Log/XSS Injection)

**Severity:** MEDIUM
**File:** `lib/reel/request/parser.rb`
**Commit:** da4ec90

**Vulnerability:** The error message for invalid Transfer-Encoding values included the raw header value via string interpolation (`"Invalid Transfer-Encoding: #{encoding}"`), which could enable log injection or XSS if error messages are rendered in HTML contexts.

**Fix:** Replaced interpolated value with a static message: `"Invalid Transfer-Encoding header value"`.

**Tests:** `spec/reel/request_parser_spec.rb` — 3 tests

---

### 4. Bare Rescue Clauses

**Severity:** MEDIUM
**Files:** `lib/reel/request/body.rb`, `lib/reel/websocket.rb`
**Commit:** d2a4e7b

**Vulnerability:** Bare `rescue` (without an exception class) catches `StandardError` but obscures intent and can mask unexpected errors during debugging.

**Fix:** Changed `rescue` to `rescue StandardError` in both files.

**Tests:** `spec/reel/bare_rescue_spec.rb` — 2 tests

---

### 5. Broken Hijack Socket State Guard

**Severity:** MEDIUM
**File:** `lib/reel/connection.rb`
**Commit:** 2eff573

**Vulnerability:** The `hijack_socket` guard compared a `StateMachine` object directly to a symbol (`@request_fsm != :ready`), which always evaluated to `true`. This made the guard depend solely on `@response_state`, allowing sockets to be hijacked from invalid states.

**Fix:** Changed to `@request_fsm.state == :headers && @response_state == :headers`, properly checking both states.

**Tests:** `spec/reel/hijack_guard_spec.rb` — 2 tests

---

### 6. No Request Body Size Limits (Memory Exhaustion DoS)

**Severity:** LOW
**File:** `lib/reel/request/body.rb`
**Commit:** 015b41f

**Vulnerability:** `Request::Body#to_str` read the entire body into memory with no size limit, allowing memory exhaustion via arbitrarily large request bodies.

**Fix:** Added configurable `max_body_size` parameter (default 10 MB) that raises `Reel::RequestError` when exceeded. Can be customized or disabled with `max_body_size: nil`.

**Tests:** `spec/reel/request_body_limit_spec.rb` — 4 tests

---

### 7. No Connection Read Timeouts (Slowloris DoS)

**Severity:** LOW
**File:** `lib/reel/connection.rb`
**Commit:** 2e8c0b7

**Vulnerability:** No timeout on socket reads — a slow client could hold a connection open indefinitely, tying up a Celluloid actor.

**Fix:** Added configurable `timeout` parameter (default 30 seconds) using `Celluloid.timeout`. Raises `Reel::RequestError` when exceeded. Can be customized or disabled with `timeout: nil`.

**Tests:** `spec/reel/connection_timeout_spec.rb` — 2 tests

---

### 8. Shell Execution in Gemspec

**Severity:** LOW
**File:** `reel.gemspec`
**Commit:** 87c26d3

**Vulnerability:** Gemspec used backtick shell execution (`` `git ls-files` ``) to determine file lists, executing an external command during `gem build`/`gem install`.

**Fix:** Replaced with `Dir.glob` for safe, deterministic file listing.

**Tests:** `spec/reel/gemspec_spec.rb` — 1 test

---

### 9. Unbounded Dependency Versions

**Severity:** LOW
**File:** `reel.gemspec`
**Commit:** 979bda7

**Vulnerability:** All runtime dependencies used unbounded `>=` constraints, meaning a future major version bump or supply chain compromise would automatically affect users.

**Fix:** Pinned to current major versions using pessimistic (`~>`) constraints:
- `celluloid ~> 0.18` (was `>= 0.15.1`)
- `celluloid-io ~> 0.17` (was `>= 0.15.0`)
- `celluloid-fsm ~> 0.20` (was `>= 0.20.0`)
- `http ~> 5.0` (was `>= 0.6.0`)
- `websocket-driver ~> 0.8` (was `>= 0.5.1`)

**Tests:** `spec/reel/dependency_bounds_spec.rb` — 1 test

---

### 10. Silent VERIFY_NONE Default for HTTPS

**Severity:** LOW
**File:** `lib/reel/server/https.rb`
**Commit:** 3be1ae4

**Vulnerability:** When no CA configuration was provided, the HTTPS server silently defaulted to `OpenSSL::SSL::VERIFY_NONE`, which could lead operators to believe mutual TLS was active when it was not.

**Fix:** Added a warning log message when defaulting to `VERIFY_NONE`, advising operators to configure `:ca_file`, `:ca_path`, or `:verify_mode`.

**Tests:** `spec/reel/https_verify_mode_spec.rb` — 1 test

---

## Summary

| # | Issue | Severity | Commit | Tests |
|---|-------|----------|--------|-------|
| 1 | ReDoS/regex injection in header lookup | HIGH | ea68104 | 6 |
| 2 | CRLF injection in response headers | HIGH | 5a10f27 | 7 |
| 3 | User input in error messages | MEDIUM | da4ec90 | 3 |
| 4 | Bare rescue clauses | MEDIUM | d2a4e7b | 2 |
| 5 | Broken hijack socket state guard | MEDIUM | 2eff573 | 2 |
| 6 | No request body size limits | LOW | 015b41f | 4 |
| 7 | No connection read timeouts | LOW | 2e8c0b7 | 2 |
| 8 | Shell execution in gemspec | LOW | 87c26d3 | 1 |
| 9 | Unbounded dependency versions | LOW | 979bda7 | 1 |
| 10 | Silent VERIFY_NONE default | LOW | 3be1ae4 | 1 |

**Total: 10 issues fixed, 29 new tests added**
