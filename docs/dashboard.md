# Dashboard

Relacionado: [[Home]], [[roadmap]]

## Notas editadas recientemente
```dataview
TABLE file.folder AS "Carpeta", file.mtime AS "Editada"
FROM ""
WHERE file.name != "dashboard"
SORT file.mtime DESC
LIMIT 10
```

## Specs por estado
```dataview
TABLE estado AS "Estado", metrica AS "Métrica que mueve"
FROM ""
WHERE estado AND !contains(file.folder, "templates")
SORT estado ASC
```

## Notas sin enlaces entrantes (huérfanas)
```dataview
LIST
FROM ""
WHERE length(file.inlinks) = 0 AND file.name != "Home"
```
