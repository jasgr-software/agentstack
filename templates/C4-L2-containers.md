# C4 Level 2: Containers

What are the high-level technology choices and how do containers communicate?

## Containers

<!-- TODO: List each deployable unit / process -->

| Container | Technology | Purpose | Port |
|-----------|-----------|---------|------|
| <!-- e.g. Web App --> | <!-- e.g. Next.js 15, React --> | <!-- e.g. Browser-based UI --> | <!-- e.g. 3000 --> |
| <!-- e.g. API Server --> | <!-- e.g. Go, Chi --> | <!-- e.g. REST API, business logic --> | <!-- e.g. 8080 --> |
| <!-- e.g. Database --> | <!-- e.g. PostgreSQL 16 --> | <!-- e.g. Persistent storage --> | <!-- e.g. 5432 --> |

## Container Relationships

<!-- TODO: How do containers talk to each other? -->

```
[Web App] --HTTP/JSON--> [API Server] --SQL--> [Database]
[API Server] --HTTP--> [GitHub API]
[API Server] --HTTP--> [Slack API]
```

---

## Change Log

<!-- SA appends an entry after each epic -->

| Date | Epic | Changes |
|------|------|---------|
