# TODO

- [ ] **Add SonarQube Container & Plugin** — Add code quality and security scanning to the demo story (typically a compose service plus dynamic plugins), so builds in Jenkins can report analysis back into the portal.

- [ ] **Add an Artifact Repository & Plugin** (e.g. Nexus, Artifactory, or Harbor) — Host Maven/npm/generic artifacts (and optionally container images) locally so the demo covers publish/consume without relying only on external registries; pairs with Quay for images.

- [ ] **Re-enable Feedback Plugin** — Re-enable feedback UI once TechDocs `viewDocs` route binding is fixed; optional email/Jira targets for collecting developer feedback from the hub.

- [ ] **Add the Jira Plugin** — Go beyond Scorecard’s Jira metrics: add the Jira entity plugin and annotations, wire API credentials, and link components to Red Hat Developer Hub work in Jira (e.g. RHIDP, RHDHPLAN, or RHDHBUGS as appropriate).

- [x] **Add 'Last' used UP configuration option** - Store the last used 'up.sh' configuration in a file, and add 'up.sh --last' as a way to start again using the last used configuration.

- [ ] **Add RHDH MCP Services & Configure Lightspeed to use them** - Activate the MCP services available for RHDH, and then include those MCP services in the configuration for Lightspeed

- [ ] **Switch to Google Gemini from Ollama** - Configure Lightspeed (Lightspeed Core/Stack https://github.com/lightspeed-core/lightspeed-stack) to use my personal google gemini pro subscription. This may require us to use VERTEX?
