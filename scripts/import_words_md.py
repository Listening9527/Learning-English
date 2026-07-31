#!/usr/bin/env python3
"""Import 14-column markdown word table into SQLite words table.

Expected markdown header:
| 单词 | 音标 | 音节划分 | 出现频率 | 词根 | 词性 | 英文释义 | 中文翻译 | 例句1 | 例句1翻译 | 例句2 | 例句2翻译 | 例句3 | 例句3翻译 |
"""

from __future__ import annotations

import argparse
import sqlite3
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


@dataclass
class WordRow:
    word: str
    phonetic: str
    syllable_division: str
    frequency: float
    word_root: str
    pos: str
    definition: str
    translation: str
    example_1: str
    example_1_translation: str
    example_2: str
    example_2_translation: str
    example_3: str
    example_3_translation: str

    @property
    def legacy_example(self) -> str:
        for value in (self.example_1, self.example_2, self.example_3):
            if value:
                return value
        return ""


def parse_frequency(value: str) -> float:
    text = value.strip()
    if not text:
        return 0.0
    try:
        return max(float(text), 0.0)
    except ValueError:
        return 0.0


def is_separator_row(cells: list[str]) -> bool:
    return all(cell.replace(":", "").replace("-", "").strip() == "" for cell in cells)


def parse_markdown_table(md_path: Path) -> list[WordRow]:
    rows: list[WordRow] = []
    for raw_line in md_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line.startswith("|"):
            continue

        cells = [cell.strip() for cell in line.strip("|").split("|")]
        if len(cells) < 14:
            continue
        if cells[0] in {"单词", "Word"}:
            continue
        if is_separator_row(cells):
            continue

        word = cells[0]
        if not word:
            continue

        rows.append(
            WordRow(
                word=word,
                phonetic=cells[1],
                syllable_division=cells[2],
                frequency=parse_frequency(cells[3]),
                word_root=cells[4],
                pos=cells[5],
                definition=cells[6],
                translation=cells[7],
                example_1=cells[8],
                example_1_translation=cells[9],
                example_2=cells[10],
                example_2_translation=cells[11],
                example_3=cells[12],
                example_3_translation=cells[13],
            )
        )

    return rows


def ensure_words_columns(conn: sqlite3.Connection, table_name: str) -> None:
    columns = {
        row[1]
        for row in conn.execute(f"PRAGMA table_info({table_name});")
    }
    required = {
        "word",
        "phonetic",
        "syllable_division",
        "frequency",
        "word_root",
        "pos",
        "definition",
        "translation",
        "example",
        "example_1",
        "example_1_translation",
        "example_2",
        "example_2_translation",
        "example_3",
        "example_3_translation",
        "type",
        "is_custom",
    }
    missing = required - columns
    if missing:
        joined = ", ".join(sorted(missing))
        raise RuntimeError(f"Table '{table_name}' missing required columns: {joined}")


def select_existing_id(conn: sqlite3.Connection, table_name: str, row: WordRow) -> int | None:
    sql = f"""
    SELECT id
    FROM {table_name}
    WHERE word = ?
      AND COALESCE(pos, '') = COALESCE(?, '')
      AND COALESCE(definition, '') = COALESCE(?, '')
      AND COALESCE(translation, '') = COALESCE(?, '')
    ORDER BY id ASC
    LIMIT 1;
    """
    data = conn.execute(sql, (row.word, row.pos, row.definition, row.translation)).fetchone()
    return int(data[0]) if data else None


def insert_row(conn: sqlite3.Connection, table_name: str, row: WordRow, is_custom: int) -> None:
    sql = f"""
    INSERT INTO {table_name} (
        word, phonetic, syllable_division, frequency, word_root, pos,
        definition, translation, example,
        example_1, example_1_translation,
        example_2, example_2_translation,
        example_3, example_3_translation,
        type, is_custom, created_at, updated_at
    )
    VALUES (
        ?, ?, ?, ?, ?, ?,
        ?, ?, ?,
        ?, ?,
        ?, ?,
        ?, ?,
        'word', ?, datetime('now'), datetime('now')
    );
    """
    conn.execute(
        sql,
        (
            row.word,
            row.phonetic,
            row.syllable_division,
            row.frequency,
            row.word_root,
            row.pos,
            row.definition,
            row.translation,
            row.legacy_example,
            row.example_1,
            row.example_1_translation,
            row.example_2,
            row.example_2_translation,
            row.example_3,
            row.example_3_translation,
            is_custom,
        ),
    )


def update_row(conn: sqlite3.Connection, table_name: str, row_id: int, row: WordRow, is_custom: int) -> None:
    sql = f"""
    UPDATE {table_name}
    SET phonetic = ?,
        syllable_division = ?,
        frequency = ?,
        word_root = ?,
        pos = ?,
        definition = ?,
        translation = ?,
        example = ?,
        example_1 = ?,
        example_1_translation = ?,
        example_2 = ?,
        example_2_translation = ?,
        example_3 = ?,
        example_3_translation = ?,
        type = 'word',
        is_custom = ?,
        updated_at = datetime('now')
    WHERE id = ?;
    """
    conn.execute(
        sql,
        (
            row.phonetic,
            row.syllable_division,
            row.frequency,
            row.word_root,
            row.pos,
            row.definition,
            row.translation,
            row.legacy_example,
            row.example_1,
            row.example_1_translation,
            row.example_2,
            row.example_2_translation,
            row.example_3,
            row.example_3_translation,
            is_custom,
            row_id,
        ),
    )


def iter_slice(rows: list[WordRow], offset: int, limit: int | None) -> Iterable[WordRow]:
    start = max(offset, 0)
    if limit is None:
        return rows[start:]
    return rows[start:start + max(limit, 0)]


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Import words markdown table into sqlite words table")
    parser.add_argument("--input", default="words/words.md", help="markdown file path")
    parser.add_argument("--db", help="sqlite db path; required unless --dry-run")
    parser.add_argument("--table", default="words", help="target table name")
    parser.add_argument("--offset", type=int, default=0, help="row offset from parsed data")
    parser.add_argument("--limit", type=int, help="max row count to import")
    parser.add_argument("--replace", action="store_true", help="update existing rows if matched")
    parser.add_argument("--is-custom", type=int, choices=[0, 1], default=0, help="set is_custom value")
    parser.add_argument("--dry-run", action="store_true", help="parse and preview without writing db")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        raise SystemExit(f"Input file not found: {input_path}")

    rows = parse_markdown_table(input_path)
    selected_rows = list(iter_slice(rows, args.offset, args.limit))

    if args.dry_run:
        print(f"parsed={len(rows)} selected={len(selected_rows)}")
        if selected_rows:
            first = selected_rows[0]
            print(
                "first_row="
                f"word={first.word}, pos={first.pos}, freq={first.frequency}, def={first.definition[:60]}"
            )
        return 0

    if not args.db:
        raise SystemExit("--db is required when not using --dry-run")

    db_path = Path(args.db)
    if not db_path.exists():
        raise SystemExit(f"Database file not found: {db_path}")

    inserted = 0
    updated = 0
    skipped = 0

    conn = sqlite3.connect(db_path)
    try:
        ensure_words_columns(conn, args.table)
        conn.execute("BEGIN;")

        for row in selected_rows:
            existing_id = select_existing_id(conn, args.table, row)
            if existing_id is None:
                insert_row(conn, args.table, row, args.is_custom)
                inserted += 1
                continue

            if args.replace:
                update_row(conn, args.table, existing_id, row, args.is_custom)
                updated += 1
            else:
                skipped += 1

        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

    print(
        f"parsed={len(rows)} selected={len(selected_rows)} inserted={inserted} "
        f"updated={updated} skipped={skipped}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
