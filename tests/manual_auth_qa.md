# Manual QA — Login + Version Gate

Client has no automated test runner. This checklist covers every user-facing
behavior introduced by the login hardening work. Run through it whenever
either `version.py::VERSION` or the client `application/config/version`
moves.

## Pre-flight

- [ ] Server is running locally on `ws://0.0.0.0:8888/ws` (or point the
      client at the correct URL in `server_connector.gd`).
- [ ] Confirm server `walkaura_server.version.VERSION` matches the first 3
      dotted segments of client `project.godot` `config/version`.
- [ ] Wipe the local `accounts_auth_failures` table between runs that
      exercise lockout, otherwise a previous run's rows bleed over:
      `DELETE FROM accounts_auth_failures;` in psql.

## 1. Version gate — happy path

- [ ] Launch client. Login screen appears with both `v X.Y.Z.N` (client) and
      `Server: X.Y.Z` labels showing.
- [ ] Login with valid credentials succeeds and transitions to the main app.
- [ ] No update modal flashes during login.

## 2. Version gate — mismatched patch (client ahead)

- [ ] Bump client `config/version` to `0.2.6.0`, keep server at `0.2.5`.
- [ ] Relaunch client. Within a second of the socket opening, the
      "Update Required" modal appears on top of the login screen.
- [ ] Modal shows: "Your version: 0.2.6.0", "Required: 0.2.5.x".
- [ ] "Update Now" button opens the marketing URL in the default browser
      (`https://walkaura.app/download`).
- [ ] "Close Game" button exits the app cleanly.
- [ ] Client does NOT retry-reconnect in a loop — no flickering "Reconnecting"
      overlay underneath.

## 3. Version gate — mismatched patch (client behind)

- [ ] Set client to `0.2.4.9`, server to `0.2.5`. Relaunch.
- [ ] Same modal appears. Same versions labels, same buttons, same behavior.

## 4. Version gate — build counter drift is NOT a mismatch

- [ ] Client `0.2.5.200` vs server `0.2.5`. Log in normally — no modal.
- [ ] Client `0.2.5.0` vs server `0.2.5.999`. Log in normally — no modal.

## 5. Register — happy path

- [ ] From login screen tap "Create User". Enter a fresh username + 8+ char
      password. Submit.
- [ ] Green "Account created!" confirmation, then the dialog closes.

## 6. Register — errors

- [ ] Reuse an existing username. Status shows
      "That username is already taken." (not "registration failed").
- [ ] Username `ab` (2 chars). Status shows the username-invalid message.
- [ ] Username `ab cd`. Status shows the bad-chars message.
- [ ] Username `admin`. Status shows the reserved-name message.
- [ ] Password `short` (< 8 chars). Status shows the password-too-weak message.

## 7. Login — locked out

- [ ] Fresh account. From one client session, submit 5 wrong passwords in
      a row. Attempt #6 shows "Account temporarily locked. Try again in a
      few minutes." not "Incorrect username or password."
- [ ] Wait 15 minutes OR `DELETE FROM accounts_auth_failures WHERE
      username='…';`. Correct password now works.

## 8. Login — lockout pair isolation (CRITICAL)

Simulates attacker-from-one-IP trying to DoS a legitimate user.

- [ ] From client #1 (say, phone): submit 5 wrong passwords for `alice`.
      Client #1 is now locked.
- [ ] From client #2 (laptop, different IP): submit correct password for
      `alice`. Login succeeds. The lockout did NOT follow the username
      across IPs.

## 9. Login — counter cleared on success (CRITICAL REGRESSION)

- [ ] 4 wrong passwords for `alice` from the same IP.
- [ ] 1 correct password — login succeeds.
- [ ] 5 wrong passwords again. Attempt #5 is still `invalid_credentials`
      (NOT locked). The success in between reset the counter.
- [ ] 6th wrong → now locked.

## 10. Rate limit — 5 attempts / 60s / IP

- [ ] From one client, submit 5 login attempts with different usernames
      inside 60 seconds. The 6th attempt returns
      "Too many attempts. Please wait a moment. (wait Ns)" where N decays.
- [ ] After 60s elapses, login attempts succeed again.

## 11. Localization parity

- [ ] Run the server tests: `uv run pytest tests/test_error_code_parity.py`.
      All pass. If you added a new server error code, this test fails
      until you add a matching key to `GameTextEn.error_texts`.

## Recovering from a bad state

- Wipe lockout rows: `DELETE FROM accounts_auth_failures;`
- Reset in-memory rate limit: restart the server (the sliding window is
  per-process).
- Force the client version label to refresh: relaunch the client.
