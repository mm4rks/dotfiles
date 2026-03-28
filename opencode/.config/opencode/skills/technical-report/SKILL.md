---
name: technical-report
description: Instructions for writing reports with high cohesion and concrete language
---
## Technical Report Writing Guidelines

This skill focuses on the structural principles and a quality gate for technical documentation.

### 1. Structural Cohesion
- **Topic Position (The Hook)**: Start sentences with "old information" that links back to the previous sentence.
- **Stress Position (The Payoff)**: Place the most important new information or the main action at the end of the sentence.
- **The Chain of Thought**: Create a cohesive flow where the topic of sentence $N$ refers to the stress of sentence $N-1$.
- **Subject-Verb Proximity**: Minimize the distance between the subject and the main verb. If more than 10 words separate them, restructure.
- **Anti-Nominalization**: Kill "smothered verbs." Use "analyzed" instead of "performed an analysis of," and "implemented" instead of "carried out the implementation of."
- **Fuzzy Subjects**: Avoid expletive constructions ("It is...", "There are..."). Identify the real actor and put it in the topic position.
- **OCAR Narrative Arc**:
  - **Opening**: Set the scene and problem.
  - **Challenge**: State the specific question or gap.
  - **Action**: Detail the implementation or findings.
  - **Resolution**: Provide the "So What?" and the kicker for the next section.

### Quality Gate
Separate pass. Do not skip.

Re-read the full draft and fix every instance of:

#### Banned Vocabulary (Never use these. Find concrete alternatives.)
| Banned | Use instead |
| :--- | :--- |
| Additionally | "Also" or restructure |
| Crucial / Pivotal / Key (adj) | Be specific about why it matters |
| Delve / Delve into | "examine", "look at", or just start |
| Enhance / Fostering | Be specific about what improved |
| Landscape (abstract) | Name the actual domain |
| Tapestry (figurative) | Name the actual pattern |
| Underscore / Highlight (verb) | State the point directly |
| Showcase | "shows", "demonstrates" |
| Vibrant / Rich (figurative) | Be specific |
| Testament / Enduring | Just state the fact |
| Groundbreaking / Renowned | Be specific about what's notable |
| Garner | "get", "earn", "attract" |
| Intricate / Intricacies | "complex" or describe the actual complexity |
| Interplay | "relationship", "tension", or describe it |
| Serves as / Stands as | Use "is" |
| Nestled / In the heart of | Just name the location |

#### Banned Structures
| Pattern | Fix |
| :--- | :--- |
| "Not just X, it's Y" / "Not A, but B" | State Y directly |
| Rule of three ("innovation, inspiration, and insights") | Use the number of items the content needs |
| "-ing" analysis ("highlighting the importance of...") | State the importance directly |
| "From X to Y" (false ranges) | List the actual items |
| Synonym cycling (protagonist/hero/central figure) | Pick one term, reuse it |
| "Despite challenges, the future looks bright" | State the actual situation |
| "Exciting times lie ahead" | End with a specific fact |
| "X wasn't Y. It was Z." (dramatic reveal) | Collapse to single positive statement |
| "The detail that stopped me in my tracks" | Start with the fact |
| "genuinely revolutionary" | Use a specific descriptor |
| Any melodramatic one-liner meant to sound profound | Delete it |
| "I'd forgotten I knew" | Delete. Never frame knowledge as rediscovered. |

### 3. Checklist
- **ABSOLUTE**: NEVER use em dashes (—). Convert to commas, colons, or periods.
- **Check links**: Every source has a real URL. No placeholders.
- **Check word repetition**: Any word appearing 3+ times in a paragraph. Vary or reduce.
- **Opening Integrity**: Does it sound like a person or like an AI summarizing a book? If the latter, rewrite.
- **Synthesis**: Verify every section connects to material beyond the source itself. No pure summary.
- **Active Voice**: Transform passive constructions to active ones.
- **Quantifiable Metrics**: Replace vague descriptors with data (e.g., "reduced latency by 45%").
- **Eliminate "Ease" Words**: Ban "simply," "easily," "just," and "obviously."
- **Parallelism**: Bullet points must start with the same part of speech.
