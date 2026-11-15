# Offline ZIP downloads

Open a saved program and choose **Descargar para usar sin internet**. The ZIP
contains the entire selected spreadsheet copy, regardless of the current day or
activity filter, plus its currently associated documents.

Extract the whole ZIP before opening `index.html` in a browser. Keep the HTML
files, `assets/`, and `documents/` together. No local server or installation is
required. The package is intended for desktop browsers; opening extracted HTML
and navigating between local files may be restricted by mobile file viewers.

The export shows when the ZIP was generated. It never updates automatically. Download and extract a new ZIP to get
later changes. External sites still require internet access.

## Implementation

`SpreadsheetCopy::OfflineExport#write_to(path)` renders static pages using the
existing program model and shared detail presentation. Styles are bundled locally;
there is no Turbo, JavaScript, or runtime network dependency. Documents are copied
from Active Storage in chunks, and the completed ZIP is streamed from a temporary
file that is removed after the response finishes.

Documents are not versioned by spreadsheet copy. The export includes the documents
available at generation time for the program's unique, stable act IDs. Removed,
missing-ID, or duplicate-ID associations are excluded. If a referenced attachment
is missing from storage, the download fails rather than returning an incomplete
archive.

## Verification

```sh
bin/rails test test/models/spreadsheet_copy/offline_export_test.rb test/integration/offline_downloads_test.rb
bin/rails test test/system/offline_exports_test.rb
```

The system test extracts the archive, opens it through `file://`, blocks HTTP and
HTTPS requests, and exercises day navigation, activity details, related acts,
styles, and a local attachment.
