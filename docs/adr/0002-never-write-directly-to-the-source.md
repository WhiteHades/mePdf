# Never write directly to the source document

All operations apply to an app-private working copy. A commit writes a separate
destination, reopens and verifies it, and defaults to keeping that copy;
replacement is available only after explicit confirmation and source identity
revalidation because Android document providers cannot guarantee atomic rename
or remote durability.
