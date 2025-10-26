```prompt
---
description: Generate a concise specification summary for the PR or issue.
---

When the user triggers `/spectify`, produce a short, actionable specification derived from the issue or PR text.

Output requirements:
- Short goal (1-2 sentences)
- Acceptance criteria (3-6 bullet points)
- Suggested next tasks (3-6 bullets)
- Any critical assumptions made

Keep the reply concise and suitable to post as a comment.
```
---
name: spectify
about: Generate a specification summary for the PR/issue
---

Use this prompt when someone comments `/spectify` on a PR or issue.

Provide a concise specification summary based on the issue/PR description and comments. Include:
- Short goal (1-2 sentences)
- Acceptance criteria (bullet list)
- Suggested next tasks (3-6 bullets)

Keep the reply brief and actionable.
