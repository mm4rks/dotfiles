---
name: tts
description: Convert text to speech and output directly to the system speaker using the Kokoro-82M model.
---

# TTS Skill: Spoken Communication

This skill allows you to communicate with the user via voice. Use it when the user requests audio output, or when providing status updates that would benefit from spoken confirmation.

## When to Use
- Responding to "Say..." or "Speak..." commands.
- Providing high-priority alerts or status changes.
- Enhancing the user experience with natural voice interaction.

## How to Use
Invoke the `tts` tool from the sandbox command line:
`tts "<text>" [voice]`

### Parameters
- **text**: The text you want the agent to speak. Keep it concise.
- **voice** (Optional): The voice ID to use. Default is `af_bella`.
  - Female: `af_bella`, `af_sarah`, `af_nicole`, `af_sky`
  - Male: `am_adam`, `am_michael`

## Best Practices
1. **Conciseness**: Spoken text should be shorter than written text. Summarize if necessary.
2. **Context**: Do not speak long blocks of code or technical logs unless explicitly asked.
3. **Selection**: Choose a voice that matches the persona or user preference if known.
