# 08 - Catalog Providers and State Management

`app.dart` provides one repository, `CategoryProvider`, a Home `ProductProvider`, `SearchProvider`, and existing navigation state. Tests inject a fake repository. Pushed listings/details own scoped ProductProviders, preserving parent listing state on back.

Category state owns root data/detail/loading/error/retry. Product state owns list/detail/page metadata/sort/filters/refresh/load-more/selected variation. Search owns query, 400 ms debounce, results, page, sort, and filters.

Generation counters prevent stale overwrite. Load-more is blocked while running or after API `last=true`; appends deduplicate by ID; failures preserve current content. Refresh, sort, filter, and query restart at page zero. Search timers are cancelled on clear/dispose. Providers publish safe user messages rather than raw exceptions.
