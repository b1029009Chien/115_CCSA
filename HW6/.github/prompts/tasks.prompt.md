```prompt
---
description: Generate a concrete task checklist derived from the PR/issue description.
---

When the user triggers `/tasks`, produce a prioritized checklist of tasks suitable for creating a milestone or issue tracker.

Output requirements:
- Ordered task list (with short descriptions)
- Suggested labels (e.g., bug, enhancement, docs)
- Estimated effort category for each task (small/medium/large)

Return in markdown checklist format so it can be pasted into an issue comment.
```
