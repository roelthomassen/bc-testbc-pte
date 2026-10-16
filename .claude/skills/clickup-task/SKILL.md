---
name: clickup-task
description: Use to read a ClickUp task and turn it into a spec, or to update
 a task's status or post a comment. Triggers on "/clickup-task start <id>",
 "/clickup-task status <id> <status>", "/clickup-task comment <id> <text>".
---
# ClickUp task handling
 
Valid statuses: Backlog, Analysis, Ready for Dev, In Development,
Code Review, On TEST, Rework, Accepted, On LIVE, Closed.
 
## start <id>
1. Fetch the task, its custom fields and comments via the ClickUp MCP server.
2. Write docs/specs/CU-<id>.md with the sections: Business need,
  Acceptance criteria (numbered, testable), Type (Feature/Change/Bug),
  Open questions, Plan (empty - filled after approval in /new-feature).
3. Check that the current git branch name contains CU-<id>; warn if not
  and do not continue until the user confirms.
4. Set the status to "In Development" and post a comment with the branch name.
 
## status <id> <status>
Set the status. Post a one-line comment with the reason and, if a pull
request exists for the current branch, its URL.
 
## Boundaries
- Never change assignees, due dates, estimates or other tasks unless asked.
- If ClickUp is unreachable, say so and give the text to paste manually.