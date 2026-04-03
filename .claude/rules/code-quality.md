---
description: Code quality standards for all files
---

# Code Quality Rules

- Keep functions small and focused - one function does one thing
- Use clear, descriptive names (a reader should understand what something does without reading the implementation)
- Handle errors explicitly - don't let errors silently fail
- Add error handling on ALL network requests and file operations
- Don't repeat yourself - if the same logic exists in 3+ places, extract it into a shared function
- Keep dependencies minimal - don't add a library for something achievable in a few lines
- Write code that's easy to delete - loosely coupled, clearly bounded modules
- When something breaks, fix the root cause, not the symptom

## Streamlit-Specific Rules
- NEVER use `use_container_width=True` on display components (`st.dataframe`, `st.data_editor`, `st.plotly_chart`, `st.altair_chart`, `st.pyplot`, `st.image`) — use `width="stretch"` instead. `use_container_width` is deprecated and will be removed after 2025-12-31.
- `use_container_width=True` on interactive widgets (`st.button`, `st.text_input`, etc.) is still valid — only display components are affected.
