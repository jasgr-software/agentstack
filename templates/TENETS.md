# Architectural Tenets

Tenets are the guiding principles for technical decisions in this project. When two valid approaches exist, tenets break the tie. Agents should consult this file before making structural choices.

> Tenets are ordered by priority. When tenets conflict, higher-ranked tenets win.

<!-- TODO: Define your project's tenets. Below are examples — replace with your own. -->

## 1. <!-- e.g. Simplicity over flexibility -->

<!-- e.g. Prefer the simpler solution even if it's less flexible. Add abstraction only when
a concrete second use case exists, not in anticipation of one. Three similar lines of code
is better than a premature abstraction. -->

## 2. <!-- e.g. API contract first -->

<!-- e.g. Define the API contract (routes, request/response shapes, error codes) before writing
any implementation. The contract is the source of truth. Clients are built against the contract,
not discovered from implementation. -->

## 3. <!-- e.g. Tests prove behavior, not coverage -->

<!-- e.g. Write tests that verify user-visible behavior and edge cases. Do not write tests
solely to increase coverage numbers. A well-placed integration test is worth more than ten
unit tests that mock everything. -->

## 4. <!-- e.g. Errors are first-class -->

<!-- e.g. Every error path must be handled explicitly. No silent swallowing, no generic catch-all.
Error messages should be actionable — tell the user or developer what went wrong and what to do. -->

## 5. <!-- e.g. Security by default -->

<!-- e.g. Authentication and authorization are not features — they are constraints applied to
every endpoint by default. New routes are authenticated unless explicitly marked public with
a documented reason. -->
