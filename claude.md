# Project Constitution

## Data Schemas
*(To be defined after Discovery phase)*

## Behavioral Rules
- Follow the B.L.A.S.T. Protocol.
- Build deterministic, self-healing automation.
- Prioritize reliability over speed.
- Never guess at business logic.
- Follow the "Data-First" Rule: Code only begins once the payload shape is confirmed.

## Architectural Invariants
- 3-Layer Architecture (A.N.T: Architecture, Navigation, Tools).
- LLMs are probabilistic; business logic must be deterministic.
- If logic changes, update the SOP before updating the code.
- Python tools must be atomic and testable.
- .tmp/ is for ephemeral files, Global (Cloud) is the delivery target.
