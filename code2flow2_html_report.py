
import ast
import base64
import csv
import subprocess
import sys
import struct
import tokenize
import tempfile
import html
import json
from pathlib import Path
from collections import Counter, defaultdict
from xml.sax.saxutils import escape



# =========================================================
# 1. CONFIGURATION
# =========================================================

project_root = Path(
    r"C:\Users\kishore\PycharmProjects\graph_test"
).resolve()

output_dir = project_root / "_code2flow_diagnostics"
output_dir.mkdir(exist_ok=True)

# Clean up old diagnostic test images/Graphviz files from earlier script versions.
# Only files named test_<number>.png or test_<number>.gv are removed.
for old_test_file in output_dir.rglob("test_*.*"):
    if old_test_file.is_file() and old_test_file.suffix.lower() in {".png", ".gv"}:
        try:
            old_test_file.unlink()
        except OSError as exc:
            print(f"Could not remove old test artifact {old_test_file}: {exc}")

graph_png = project_root / "project_callgraph.png"
combined_svg = project_root / "project_callgraph_summary.svg"
function_csv = project_root / "function_metrics.csv"
imports_csv = project_root / "imports_summary.csv"
library_summary_csv = project_root / "distinct_library_summary.csv"
html_report = project_root / "project_report.html"

excluded_dirs = {
    ".git",
    ".venv",
    "venv",
    "__pycache__",
    ".idea",
    "_code2flow_diagnostics",
}

script_path = Path(__file__).resolve()


def run_code2flow(arguments, timeout=60):
    """Invoke Code2flow through its Python entry point."""
    runner = (
        "import sys; "
        "from code2flow.engine import main; "
        "sys.argv = ['code2flow'] + sys.argv[1:]; "
        "main()"
    )
    return subprocess.run(
        [sys.executable, "-c", runner, *[str(arg) for arg in arguments]],
        capture_output=True, text=True, errors="replace", timeout=timeout,
    )


def create_html_report(
    html_report, project_root, python_files, file_records, function_records,
    unique_imports, category_counts, orphan_candidates, leaf_functions,
    largest_functions, total_lines, total_code_lines, total_functions,
    total_classes, parse_errors, import_records, library_summary_csv,
):
    """Create a self-contained, searchable, single-page HTML report."""
    def esc(value):
        return html.escape(str(value), quote=True)

    def make_table(headers, rows, empty_message="No records available."):
        header_html = "".join(f"<th>{esc(item)}</th>" for item in headers)
        if rows:
            body_html = "".join(
                "<tr>" + "".join(f"<td>{esc(value)}</td>" for value in row) + "</tr>"
                for row in rows
            )
        else:
            body_html = (
                f'<tr><td colspan="{len(headers)}" class="empty">'
                f'{esc(empty_message)}</td></tr>'
            )
        return (
            '<div class="table-wrap"><table><thead><tr>' + header_html +
            '</tr></thead><tbody>' + body_html + '</tbody></table></div>'
        )

    file_rows = sorted(file_records, key=lambda item: (-item["total_lines"], item["file"]))
    function_rows = sorted(function_records, key=lambda item: (-item["code_lines"], item["file"], item["function"]))

    library_rows = []
    if library_summary_csv.exists():
        try:
            with library_summary_csv.open("r", newline="", encoding="utf-8-sig") as source:
                library_rows = list(csv.DictReader(source))
        except OSError:
            pass

    library_table_rows = [
        (row.get("category", ""), row.get("library", ""),
         row.get("distinct_import_paths", ""), row.get("files_count", ""),
         row.get("imported_module_paths", ""))
        for row in library_rows
    ]
    file_table_rows = [
        (row["file"], f'{row["total_lines"]:,}', f'{row["code_lines"]:,}',
         row["function_count"], row["class_count"])
        for row in file_rows
    ]
    function_table_rows = [
        (row["file"], row["function"], row["code_lines"], row["start_line"],
         row["end_line"], row["call_count"], row["caller_count"])
        for row in function_rows
    ]
    orphan_table_rows = [
        (row["file"], row["function"], row["code_lines"], row["call_count"])
        for row in sorted(orphan_candidates, key=lambda item: (-item["code_lines"], item["file"]))
    ]
    leaf_table_rows = [
        (row["file"], row["function"], row["code_lines"], row["call_count"], row["caller_count"])
        for row in sorted(leaf_functions, key=lambda item: (-item["code_lines"], item["file"]))
    ]
    import_table_rows = [
        (row["category"], row["import_name"], row["file"])
        for row in sorted(import_records, key=lambda item: (item["category"], item["import_name"], item["file"]))
    ]
    error_table_rows = [(path, message) for path, message in parse_errors]

    code_pct = (total_code_lines / total_lines * 100) if total_lines else 0
    other_lines = max(0, total_lines - total_code_lines)
    category_html = "".join(
        f'<div class="category-row"><span>{esc(category)}</span><strong>{count}</strong></div>'
        for category, count in sorted(category_counts.items())
    ) or '<p class="muted">No import records found.</p>'

    report_html = f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Python Project Assessment - {esc(project_root.name)}</title>
<style>
:root{{--ink:#172033;--muted:#667085;--line:#e4e7ec;--paper:#f5f7fb;--card:#fff;--accent:#2859a8;--green:#167d68}}
*{{box-sizing:border-box}}body{{margin:0;background:var(--paper);color:var(--ink);font:14px/1.5 "Segoe UI",Arial,sans-serif}}
header{{background:#14233b;color:white;padding:28px clamp(18px,4vw,52px)}}header h1{{margin:0 0 7px;font-size:clamp(24px,3vw,34px)}}header p{{margin:4px 0;color:#d3dced;overflow-wrap:anywhere}}
main{{max-width:1500px;margin:auto;padding:24px clamp(14px,3vw,40px) 48px}}.section{{margin:24px 0}}.section h2{{font-size:20px;margin:0 0 12px}}
.cards{{display:grid;grid-template-columns:repeat(auto-fit,minmax(165px,1fr));gap:13px}}.card,.panel{{background:var(--card);border:1px solid var(--line);border-radius:13px;padding:17px;box-shadow:0 2px 8px #17203308}}
.card .label{{color:var(--muted);font-size:12px;text-transform:uppercase;letter-spacing:.06em}}.card .value{{font-size:29px;font-weight:700;margin-top:6px}}.card .hint{{color:var(--muted);font-size:12px;margin-top:2px}}
.panel{{margin-top:13px}}.bar{{height:13px;display:flex;overflow:hidden;border-radius:99px;background:#e8edf5;margin:12px 0 8px}}.bar .code{{background:var(--green);width:CODE_PERCENT%}}.bar .other{{background:#a9b7cc;flex:1}}
.legend{{display:flex;flex-wrap:wrap;gap:16px;color:var(--muted);font-size:12px}}.dot{{display:inline-block;width:9px;height:9px;border-radius:50%;margin-right:6px;background:var(--green)}}.dot.other{{background:#a9b7cc}}
.split{{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:14px}}.category-row{{display:flex;justify-content:space-between;gap:16px;padding:9px 0;border-bottom:1px solid var(--line)}}
.toolbar{{display:flex;flex-wrap:wrap;gap:10px;align-items:center;margin:12px 0}}input[type=search]{{width:min(100%,420px);border:1px solid #cfd6e2;border-radius:8px;padding:10px 12px;font:inherit;background:white}}
button{{border:1px solid #cfd6e2;background:white;padding:9px 12px;border-radius:8px;cursor:pointer;color:var(--ink)}}.table-wrap{{overflow:auto;max-height:560px;border:1px solid var(--line);border-radius:10px;background:white}}
table{{width:100%;border-collapse:collapse;font-size:12px}}th,td{{text-align:left;padding:9px 11px;border-bottom:1px solid var(--line);vertical-align:top}}th{{position:sticky;top:0;background:#eef2f8;z-index:1;font-size:11px;text-transform:uppercase;letter-spacing:.04em;white-space:nowrap}}td{{overflow-wrap:anywhere}}tr:last-child td{{border-bottom:0}}
.empty,.muted,.note{{color:var(--muted)}}.note{{font-size:12px;margin-top:9px}}.badge{{display:inline-block;padding:3px 8px;border-radius:99px;background:#e9f7f2;color:#116650;font-size:12px;font-weight:600}}.badge.warn{{background:#fff3db;color:#8a5200}}
footer{{color:var(--muted);font-size:12px;padding:20px 0 0}}@media print{{body{{background:white}}header{{background:#14233b!important;print-color-adjust:exact}}.table-wrap{{max-height:none;overflow:visible}}.toolbar,button{{display:none}}.card,.panel{{break-inside:avoid;box-shadow:none}}}}
</style></head><body>
<header><h1>Python Project Assessment</h1><p><strong>Project:</strong> {esc(project_root.name)}</p><p><strong>Root path:</strong> {esc(project_root)}</p><p>Code inventory · Function metrics · Library dependencies · Call graph analysis</p></header>
<main>
<section class="section"><h2>Executive summary</h2><div class="cards">
<div class="card"><div class="label">Python files</div><div class="value">{len(python_files):,}</div><div class="hint">Discovered in project</div></div>
<div class="card"><div class="label">Physical lines</div><div class="value">{total_lines:,}</div><div class="hint">Includes blank/comment lines</div></div>
<div class="card"><div class="label">Code lines</div><div class="value">{total_code_lines:,}</div><div class="hint">Excludes blank/comment-only lines</div></div>
<div class="card"><div class="label">Functions / methods</div><div class="value">{total_functions:,}</div><div class="hint">Including nested functions</div></div>
<div class="card"><div class="label">Classes</div><div class="value">{total_classes:,}</div><div class="hint">Across analyzed files</div></div>
<div class="card"><div class="label">Distinct import names</div><div class="value">{len(unique_imports):,}</div><div class="hint">Import module names</div></div>
<div class="card"><div class="label">Files analyzed</div><div class="value">{len(file_records):,}</div><div class="hint">Of {len(python_files):,} discovered</div></div>
<div class="card"><div class="label">Parse errors</div><div class="value">{len(parse_errors):,}</div><div class="hint">Syntax or encoding issues</div></div>
</div><div class="panel"><strong>Source composition</strong><div class="bar"><div class="code"></div><div class="other"></div></div><div class="legend"><span><i class="dot"></i>Code lines: {total_code_lines:,} ({code_pct:.1f}%)</span><span><i class="dot other"></i>Other physical lines: {other_lines:,} ({100-code_pct:.1f}%)</span></div></div></section>
<section class="section split"><div class="panel"><h2>Import categories</h2>{category_html}<p class="note">Counts represent import records by category, not necessarily installed packages.</p></div><div class="panel"><h2>Analysis status</h2><p><span class="badge">{len(file_records)} files analyzed</span></p><p><span class="badge warn">{len(orphan_candidates)} no-caller candidates</span></p><p><span class="badge">{len(leaf_functions)} functions call nothing else</span></p><p class="note">No detected callers does not prove a function is unused; entry points and dynamic calls may be missed.</p></div></section>
<section class="section"><h2>Distinct libraries</h2><p class="muted">One row per distinct top-level library. Classification is approximate; unrecognized modules are grouped as third-party or unknown.</p><div class="toolbar"><input type="search" data-filter="libraries" placeholder="Search libraries or category"><button onclick="downloadCsv('libraries')">Download CSV</button></div><div id="libraries">{make_table(["Category","Library","Import paths","Files count","Imported module paths"], library_table_rows)}</div></section>
<section class="section"><h2>File-level metrics</h2><div class="toolbar"><input type="search" data-filter="files" placeholder="Search file names"><button onclick="downloadCsv('files')">Download CSV</button></div><div id="files">{make_table(["File","Physical lines","Code lines","Functions","Classes"], file_table_rows)}</div></section>
<section class="section"><h2>Function metrics</h2><p class="muted">Nested function line counts can overlap with enclosing function spans.</p><div class="toolbar"><input type="search" data-filter="functions" placeholder="Search file, function, or metrics"><button onclick="downloadCsv('functions')">Download CSV</button></div><div id="functions">{make_table(["File","Function","Code lines","Start line","End line","Call count","Estimated callers"], function_table_rows)}</div></section>
<section class="section"><h2>Functions with no detected callers</h2><p class="muted">Candidates for review, not a definitive unused-code report.</p><div class="toolbar"><input type="search" data-filter="orphans" placeholder="Search candidate functions"><button onclick="downloadCsv('orphans')">Download CSV</button></div><div id="orphans">{make_table(["File","Function","Code lines","Call count"], orphan_table_rows)}</div></section>
<section class="section"><h2>Functions that call nothing else</h2><div class="toolbar"><input type="search" data-filter="leaves" placeholder="Search functions"><button onclick="downloadCsv('leaves')">Download CSV</button></div><div id="leaves">{make_table(["File","Function","Code lines","Call count","Estimated callers"], leaf_table_rows)}</div></section>
<section class="section"><h2>Import statements by file</h2><div class="toolbar"><input type="search" data-filter="imports" placeholder="Search imports or files"><button onclick="downloadCsv('imports')">Download CSV</button></div><div id="imports">{make_table(["Category","Import module","File"], import_table_rows)}</div></section>
<section class="section"><h2>Parse / encoding errors</h2><div id="errors">{make_table(["File","Error"], error_table_rows, "No syntax or encoding errors detected by this analyzer.")}</div></section>
<section class="section"><h2>Methodology and limitations</h2><div class="panel"><ul><li>Code lines are lines containing Python tokens, excluding blank lines and comment-only lines.</li><li>Call detection may miss dynamic calls, aliases, reflection, and runtime dispatch.</li><li>Caller counts are name-based estimates and may overcount functions with the same name in different modules.</li><li>Import classification is approximate and does not inspect installed package metadata.</li><li>Nested function LOC can overlap with the enclosing function's LOC.</li></ul></div></section>
<footer>Generated by the local Python code visualization script. This report is self-contained and works offline in a browser.</footer>
</main>
<script>
const csvData = __CSV_DATA__;
document.querySelectorAll('input[data-filter]').forEach(input => {{ input.addEventListener('input', () => {{ const target=document.getElementById(input.dataset.filter); const query=input.value.toLowerCase(); target.querySelectorAll('tbody tr').forEach(row => {{ row.style.display=row.innerText.toLowerCase().includes(query)?'':'none'; }}); }}); }});
function downloadCsv(key) {{ const data=csvData[key]; const quote=value=>'"'+String(value??'').replaceAll('"','""')+'"'; const rows=[data.headers,...data.rows]; const content=rows.map(row=>row.map(quote).join(',')).join('\\r\\n'); const blob=new Blob(['\\ufeff'+content],{{type:'text/csv;charset=utf-8;'}}); const url=URL.createObjectURL(blob); const a=document.createElement('a');a.href=url;a.download=key+'_report.csv';a.click();URL.revokeObjectURL(url); }}
</script></body></html>'''

    report_html = report_html.replace("CODE_PERCENT", f"{code_pct:.2f}")
    csv_payload = {
        "libraries": {"headers": ["Category", "Library", "Import paths", "Files count", "Imported module paths"], "rows": library_table_rows},
        "files": {"headers": ["File", "Physical lines", "Code lines", "Functions", "Classes"], "rows": file_table_rows},
        "functions": {"headers": ["File", "Function", "Code lines", "Start line", "End line", "Call count", "Estimated callers"], "rows": function_table_rows},
        "orphans": {"headers": ["File", "Function", "Code lines", "Call count"], "rows": orphan_table_rows},
        "leaves": {"headers": ["File", "Function", "Code lines", "Call count", "Estimated callers"], "rows": leaf_table_rows},
        "imports": {"headers": ["Category", "Import module", "File"], "rows": import_table_rows},
    }
    report_html = report_html.replace("__CSV_DATA__", json.dumps(csv_payload, ensure_ascii=False).replace("</", "<\\/"))
    html_report.write_text(report_html, encoding="utf-8")

# =========================================================
# 2. DISCOVER PROJECT FILES
# =========================================================

python_files = sorted(
    p for p in project_root.rglob("*.py")
    if not any(part in excluded_dirs for part in p.parts)
    and p.resolve() != script_path
    and p != graph_png
)

try:
    import code2flow.engine  # noqa: F401
except ImportError as exc:
    raise RuntimeError(
        "Code2flow is not installed in the Python interpreter running this script. "
        "Install it in this environment or configure the correct PyCharm interpreter."
    ) from exc

if not python_files:
    raise RuntimeError("No Python files found.")

print(f"Project root: {project_root}")
print(f"Python files found: {len(python_files)}")


# =========================================================
# 3. SOURCE METRICS
# =========================================================

def get_code_lines(source):
    """Return physical line numbers containing Python code."""
    code_lines = set()

    try:
        tokens = tokenize.generate_tokens(
            iter(source.splitlines(keepends=True)).__next__
        )

        ignored = {
            tokenize.ENCODING,
            tokenize.NL,
            tokenize.NEWLINE,
            tokenize.INDENT,
            tokenize.DEDENT,
            tokenize.COMMENT,
            tokenize.ENDMARKER,
        }

        for token in tokens:
            if token.type in ignored:
                continue

            start_line = token.start[0]
            end_line = token.end[0]

            for line_number in range(start_line, end_line + 1):
                code_lines.add(line_number)

    except (tokenize.TokenError, IndentationError):
        # AST parsing will report source syntax issues separately.
        pass

    return code_lines


def get_call_name(node):
    """Get a best-effort name for a callable expression."""
    if isinstance(node, ast.Name):
        return node.id

    if isinstance(node, ast.Attribute):
        prefix = get_call_name(node.value)
        return f"{prefix}.{node.attr}" if prefix else node.attr

    if isinstance(node, ast.Call):
        return get_call_name(node.func)

    if isinstance(node, ast.Subscript):
        return get_call_name(node.value)

    return ""


def collect_calls(node):
    """Collect statically recognizable function calls."""
    calls = []

    class CallVisitor(ast.NodeVisitor):
        def visit_FunctionDef(self, child):
            if child is not node:
                return
            self.generic_visit(child)

        def visit_AsyncFunctionDef(self, child):
            if child is not node:
                return
            self.generic_visit(child)

        def visit_Lambda(self, child):
            return

        def visit_Call(self, child):
            name = get_call_name(child.func)
            if name:
                calls.append(name)
            self.generic_visit(child)

    CallVisitor().visit(node)
    return calls


def module_root(import_name):
    return import_name.split(".")[0] if import_name else ""


stdlib_modules = getattr(sys, "stdlib_module_names", set())

internal_roots = {
    p.stem for p in project_root.glob("*.py")
}
internal_roots.update(
    p.name for p in project_root.iterdir()
    if p.is_dir() and p.name not in excluded_dirs
)


# =========================================================
# 4. ANALYZE EACH FILE
# =========================================================

file_records = []
function_records = []
import_records = []
all_function_names = Counter()
parse_errors = []

for file_path in python_files:
    relative_path = str(file_path.relative_to(project_root))

    try:
        source = file_path.read_text(encoding="utf-8-sig")
        tree = ast.parse(source, filename=relative_path)
    except (SyntaxError, UnicodeDecodeError) as exc:
        parse_errors.append((relative_path, str(exc)))
        print(f"PARSE ERROR: {relative_path}: {exc}")
        continue

    lines = source.splitlines()
    code_line_numbers = get_code_lines(source)

    functions_in_file = []
    classes_in_file = []
    imports_in_file = []

    class Analyzer(ast.NodeVisitor):
        def __init__(self):
            self.scope = []

        def visit_ClassDef(self, node):
            classes_in_file.append({
                "class_name": ".".join(self.scope + [node.name]),
                "file": relative_path,
                "line": node.lineno,
            })

            self.scope.append(node.name)
            for child in node.body:
                self.visit(child)
            self.scope.pop()

        def visit_FunctionDef(self, node):
            self.add_function(node)

        def visit_AsyncFunctionDef(self, node):
            self.add_function(node)

        def add_function(self, node):
            qualified_name = ".".join(self.scope + [node.name])
            start = node.lineno
            end = getattr(node, "end_lineno", start)

            function_code_lines = sum(
                1 for line_no in code_line_numbers
                if start <= line_no <= end
            )

            calls = collect_calls(node)

            record = {
                "file": relative_path,
                "function": qualified_name,
                "start_line": start,
                "end_line": end,
                "span_lines": end - start + 1,
                "code_lines": function_code_lines,
                "call_count": len(calls),
                "calls": calls,
                "caller_count": 0,
            }

            functions_in_file.append(record)
            all_function_names[node.name] += 1

            # Visit nested functions so they are counted separately.
            self.scope.append(node.name)
            for child in node.body:
                self.visit(child)
            self.scope.pop()

        def visit_Import(self, node):
            for alias in node.names:
                imports_in_file.append(alias.name)

        def visit_ImportFrom(self, node):
            if node.module:
                imports_in_file.append(node.module)

    Analyzer().visit(tree)

    # Count physical lines, including blank/comment lines.
    total_lines = len(lines)

    # Include import usage by file.
    for import_name in sorted(set(imports_in_file)):
        root_name = module_root(import_name)

        if root_name in internal_roots:
            category = "Internal"
        elif root_name in stdlib_modules:
            category = "Standard library"
        else:
            category = "Third-party or unknown"

        import_records.append({
            "file": relative_path,
            "import_name": import_name,
            "category": category,
        })

    file_records.append({
        "file": relative_path,
        "total_lines": total_lines,
        "code_lines": len(code_line_numbers),
        "function_count": len(functions_in_file),
        "class_count": len(classes_in_file),
        "imports": sorted(set(imports_in_file)),
    })

    function_records.extend(functions_in_file)


# =========================================================
# 5. ESTIMATE FUNCTION CALLERS
# =========================================================

# This is a name-based estimate, not full semantic resolution.
for caller in function_records:
    for call_name in caller["calls"]:
        short_name = call_name.rsplit(".", 1)[-1]

        for target in function_records:
            if target["function"].rsplit(".", 1)[-1] == short_name:
                if target is not caller:
                    target["caller_count"] += 1


# =========================================================
# 6. WRITE FUNCTION METRICS CSV
# =========================================================

with function_csv.open(
    "w", newline="", encoding="utf-8-sig"
) as file:
    fieldnames = [
        "file",
        "function",
        "start_line",
        "end_line",
        "span_lines",
        "code_lines",
        "call_count",
        "caller_count",
        "calls",
    ]

    writer = csv.DictWriter(file, fieldnames=fieldnames)
    writer.writeheader()

    for record in sorted(
        function_records,
        key=lambda r: (-r["code_lines"], r["file"], r["function"])
    ):
        row = record.copy()
        row["calls"] = "; ".join(row["calls"])
        writer.writerow({key: row[key] for key in fieldnames})


# =========================================================
# 7. WRITE IMPORT SUMMARY CSV
# =========================================================

with imports_csv.open(
    "w", newline="", encoding="utf-8-sig"
) as file:
    fieldnames = ["file", "import_name", "category"]
    writer = csv.DictWriter(file, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(import_records)


# =========================================================
# 7A. DISTINCT LIBRARY SUMMARY
#     One row per distinct top-level library/module, grouped by
#     standard library, third-party/unknown, or internal project.
# =========================================================

library_details = {}

for record in import_records:
    library_name = module_root(record["import_name"])
    if not library_name:
        continue

    key = (record["category"], library_name)
    if key not in library_details:
        library_details[key] = {
            "category": record["category"],
            "library": library_name,
            "imported_module_paths": set(),
            "files": set(),
        }

    library_details[key]["imported_module_paths"].add(record["import_name"])
    library_details[key]["files"].add(record["file"])

with library_summary_csv.open(
    "w", newline="", encoding="utf-8-sig"
) as file:
    fieldnames = [
        "category",
        "library",
        "distinct_import_paths",
        "files_count",
        "imported_module_paths",
        "files",
    ]
    writer = csv.DictWriter(file, fieldnames=fieldnames)
    writer.writeheader()

    for key in sorted(library_details, key=lambda item: (item[0], item[1].lower())):
        details = library_details[key]
        writer.writerow({
            "category": details["category"],
            "library": details["library"],
            "distinct_import_paths": len(details["imported_module_paths"]),
            "files_count": len(details["files"]),
            "imported_module_paths": "; ".join(sorted(details["imported_module_paths"])),
            "files": "; ".join(sorted(details["files"])),
        })

print(f"Distinct library summary created: {library_summary_csv}")


# =========================================================
# 8. PROJECT SUMMARY
# =========================================================

total_lines = sum(r["total_lines"] for r in file_records)
total_code_lines = sum(r["code_lines"] for r in file_records)
total_functions = len(function_records)
total_classes = sum(r["class_count"] for r in file_records)

unique_imports = sorted({
    r["import_name"] for r in import_records
})

category_counts = Counter(
    r["category"] for r in import_records
)

orphan_candidates = [
    r for r in function_records
    if r["caller_count"] == 0
]

leaf_functions = [
    r for r in function_records
    if r["call_count"] == 0
]

largest_functions = sorted(
    function_records,
    key=lambda r: r["code_lines"],
    reverse=True,
)[:10]

summary_lines = [
    "PROJECT CODE SUMMARY",
    "=" * 60,
    f"Project root: {project_root}",
    f"Python files discovered: {len(python_files)}",
    f"Files successfully analyzed: {len(file_records)}",
    f"Files with syntax/encoding errors: {len(parse_errors)}",
    f"Total physical lines: {total_lines:,}",
    f"Code lines (excluding blank/comment lines): {total_code_lines:,}",
    f"Functions and methods: {total_functions:,}",
    f"Classes: {total_classes:,}",
    f"Distinct imported module names: {len(unique_imports):,}",
    "",
    "IMPORT CATEGORIES",
    "-" * 60,
]

for category, count in sorted(category_counts.items()):
    summary_lines.append(f"{category}: {count}")

summary_lines.extend([
    "",
    "IMPORTED MODULES",
    "-" * 60,
    *unique_imports,
    "",
    "LARGEST FUNCTIONS BY CODE LINES",
    "-" * 60,
])

for record in largest_functions:
    summary_lines.append(
        f'{record["code_lines"]:>5} lines | '
        f'{record["file"]} | {record["function"]}'
    )

summary_lines.extend([
    "",
    "FUNCTIONS WITH NO DETECTED CALLERS (CANDIDATES)",
    "-" * 60,
])

for record in orphan_candidates[:50]:
    summary_lines.append(
        f'{record["file"]} | {record["function"]}'
    )

summary_lines.extend([
    "",
    "FUNCTIONS THAT CALL NOTHING ELSE",
    "-" * 60,
])

for record in leaf_functions[:50]:
    summary_lines.append(
        f'{record["file"]} | {record["function"]}'
    )


create_html_report(
    html_report=html_report,
    project_root=project_root,
    python_files=python_files,
    file_records=file_records,
    function_records=function_records,
    unique_imports=unique_imports,
    category_counts=category_counts,
    orphan_candidates=orphan_candidates,
    leaf_functions=leaf_functions,
    largest_functions=largest_functions,
    total_lines=total_lines,
    total_code_lines=total_code_lines,
    total_functions=total_functions,
    total_classes=total_classes,
    parse_errors=parse_errors,
    import_records=import_records,
    library_summary_csv=library_summary_csv,
)

print("\n".join(summary_lines[:15]))
print(f"\nHTML report created: {html_report}")


# =========================================================
# 9. TEST EACH FILE WITH CODE2FLOW
#    Test artifacts are stored in temporary folders and removed
#    automatically, so test_*.png and test_*.gv do not accumulate.
# =========================================================

failed_files = []
timed_out_files = []

for index, file_path in enumerate(python_files, start=1):
    relative_path = str(file_path.relative_to(project_root))

    if not any(
        r["file"] == relative_path for r in file_records
    ):
        failed_files.append(file_path)
        continue

    try:
        with tempfile.TemporaryDirectory(prefix="code2flow_test_") as temp_dir:
            test_output = Path(temp_dir) / f"test_{index}.png"
            result = run_code2flow(
                [str(file_path), "-o", str(test_output)],
                timeout=60,
            )

        if result.returncode != 0:
            failed_files.append(file_path)
            print(f"CODE2FLOW FAILED: {file_path}")
            print((result.stderr or result.stdout)[-1000:])
        else:
            print(
                f"[{index}/{len(python_files)}] PASS: {relative_path}"
            )

    except subprocess.TimeoutExpired:
        timed_out_files.append(file_path)
        print(f"TIMEOUT: {file_path}")

# =========================================================
# 10. GENERATE COMBINED GRAPH
# =========================================================

if failed_files or timed_out_files:
    print("\nCombined graph skipped: individual tests failed.")
    print(f"Failed files: {len(failed_files)}")
    print(f"Timed-out files: {len(timed_out_files)}")

else:
    source_files = [
        str(p) for p in python_files
        if p.resolve() != script_path
    ]

    print("\nGenerating combined graph...")

    try:
        result = run_code2flow(
            [
                *source_files,
                "--skip-parse-errors",
                "-o",
                str(graph_png),
            ],
            timeout=600,
        )

        if result.returncode != 0 or not graph_png.exists():
            print("Combined graph generation failed.")
            print((result.stderr or result.stdout)[-4000:])
            sys.exit(1)

    except subprocess.TimeoutExpired:
        print("Combined graph timed out.")
        sys.exit(1)


# =========================================================
# 11. EMBED GRAPH AND SUMMARY IN ONE SVG IMAGE
# =========================================================

png_bytes = graph_png.read_bytes()
png_base64 = base64.b64encode(png_bytes).decode("ascii")

# PNG width and height are stored in its header.
graph_width, graph_height = struct.unpack(
    ">II", png_bytes[16:24]
)

header_height = 310
canvas_width = max(graph_width, 1200)
canvas_height = graph_height + header_height

def svg_text(x, y, value, size=16, bold=False):
    weight = "bold" if bold else "normal"
    return (
        f'<text x="{x}" y="{y}" '
        f'font-family="Arial, sans-serif" '
        f'font-size="{size}" font-weight="{weight}" '
        f'fill="#202124">{escape(str(value))}</text>'
    )

summary_svg = []

summary_svg.append(svg_text(
    24, 34, "PROJECT CODE SUMMARY", 25, True
))

summary_svg.append(svg_text(
    24, 66, f"Project: {project_root}", 14
))

summary_svg.append(svg_text(
    24, 105, f"Python files discovered: {len(python_files)}"
))
summary_svg.append(svg_text(
    24, 135, f"Files analyzed: {len(file_records)}"
))
summary_svg.append(svg_text(
    24, 165, f"Physical lines: {total_lines:,}"
))
summary_svg.append(svg_text(
    24, 195, f"Code lines: {total_code_lines:,}"
))
summary_svg.append(svg_text(
    24, 225, f"Functions/methods: {total_functions:,}"
))
summary_svg.append(svg_text(
    24, 255, f"Classes: {total_classes:,}"
))

summary_svg.append(svg_text(
    440, 105, f"Distinct imported modules: {len(unique_imports):,}"
))
summary_svg.append(svg_text(
    440, 135,
    f"Standard-library imports: {category_counts['Standard library']}"
))
summary_svg.append(svg_text(
    440, 165,
    f"Third-party/unknown imports: {category_counts['Third-party or unknown']}"
))
summary_svg.append(svg_text(
    440, 195,
    f"Internal imports: {category_counts['Internal']}"
))
summary_svg.append(svg_text(
    440, 225,
    f"Functions with no detected callers: {len(orphan_candidates)}"
))
summary_svg.append(svg_text(
    440, 255,
    f"Functions calling nothing else: {len(leaf_functions)}"
))
summary_svg.append(svg_text(
    24, 290,
    "Note: caller counts are name-based estimates; nested function LOC can overlap.",
    12
))

svg_document = f'''<svg xmlns="http://www.w3.org/2000/svg"
    width="{canvas_width}" height="{canvas_height}"
    viewBox="0 0 {canvas_width} {canvas_height}">
    <rect width="100%" height="100%" fill="#ffffff"/>
    <rect x="0" y="0" width="100%" height="{header_height}"
        fill="#f1f4f8"/>
    {''.join(summary_svg)}
    <image x="0" y="{header_height}"
        width="{graph_width}" height="{graph_height}"
        href="data:image/png;base64,{png_base64}"
        xmlns:xlink="http://www.w3.org/1999/xlink"
        xlink:href="data:image/png;base64,{png_base64}"/>
</svg>'''

combined_svg.write_text(svg_document, encoding="utf-8")

print("\n========== FINAL OUTPUTS ==========")
print(f"Graph PNG       : {graph_png}")
print(f"Combined image  : {combined_svg}")
print(f"Function report : {function_csv}")
print(f"Import report   : {imports_csv}")
print(f"Distinct libraries: {library_summary_csv}")
print(f"HTML report     : {html_report}")

subprocess.Popen(
    ["cmd", "/c", "start", "", str(combined_svg)]
)
subprocess.Popen(
    ["cmd", "/c", "start", "", str(html_report)]
)
