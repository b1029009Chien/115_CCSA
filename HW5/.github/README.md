# Slash commands for HW5

This folder contains prompt templates used by slash commands for the HW5 subproject.

Available commands (trigger by commenting on an issue or PR):

- `/spectify` — Generate a concise specification summary suitable for posting as a comment.
- `/paln` — Create a development plan with tasks and rough estimates.
- `/tasks` — Produce a prioritized task checklist in markdown.
- `/implement` — Provide implementation guidance and example snippets.

How it works:

1. Comment one of the commands on an issue or PR (e.g., `/tasks`).
2. The repository-level workflow `.github/workflows/slash-dispatch.yml` listens for new comments and dispatches a repository event for the matching command.
3. Each command has its own workflow (e.g., `.github/workflows/tasks.yml`) which can run CI, post results, or perform other automation.

Notes:
- The dispatch workflow is defined at the repository root. Commands in this folder are intended to be used for HW5-related issues/PRs.
- If you'd like the workflows to post the AI-generated contents automatically as a comment, we can extend the workflows to call the prompt engine and post the reply.
