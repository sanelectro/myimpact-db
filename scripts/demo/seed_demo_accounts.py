#!/usr/bin/env python3
import argparse
import hashlib
import os
import sys
import textwrap
from datetime import UTC, datetime
from pathlib import Path

from sqlalchemy import text
from sqlalchemy.engine import make_url

SCRIPT_DIR = Path(__file__).resolve().parent
WORKSPACE_ROOT = SCRIPT_DIR.parents[2]
API_ROOT = WORKSPACE_ROOT / "myimpact-api"
sys.path.insert(0, str(API_ROOT))

from app.config import get_settings
from app.database import SessionLocal
from app.security import hash_password

PERSONAS_PATH = WORKSPACE_ROOT / "myimpact-ai" / "demo-data" / "demo_personas.json"
PDF_OUTPUT_DIR = WORKSPACE_ROOT / "myimpact-web" / "public" / "demo-evidence"
CAPTURED_AT = datetime.fromisoformat("2026-10-15T12:00:00+00:00")
DEMO_ORGANIZATION = {
    "id": "organization-myimpact-demo",
    "name": "MyImpact Demo Engineering",
    "normalized_name": "myimpact-demo-engineering",
}
DEMO_ADMIN = {
    "user_id": "demo-myimpact-admin",
    "name": "MyImpact Admin",
    "email": "myimpact-admin@example.com",
}


def _goal_rows(persona: dict) -> list[dict]:
    return [
        {
            "goal_id": persona["goal_id"],
            "title": persona["goal_title"],
            "description": persona["goal_description"],
            "scope": persona["scope"],
            "status": "ACTIVE",
            "sub_status": "ON_TRACK",
        },
        *persona["additional_goals"],
    ]


def _validate_seed_personas(personas: list[dict]) -> None:
    seen_user_ids: set[str] = set()
    seen_goal_ids: set[str] = set()
    required_scopes = {"PERSONAL", "TEAM", "ORGANIZATION"}
    required_statuses = {"DRAFT", "APPROVED", "ACTIVE"}
    status_sub_status = {
        "DRAFT": "NEEDS_REVIEW",
        "APPROVED": "NOT_STARTED",
        "ACTIVE": "ON_TRACK",
    }

    for persona in personas:
        if persona["user_id"] in seen_user_ids:
            raise ValueError(f"Duplicate demo user ID: {persona['user_id']}")
        seen_user_ids.add(persona["user_id"])

        goals = _goal_rows(persona)
        scopes = {goal["scope"] for goal in goals}
        statuses = {goal["status"] for goal in goals}
        if scopes != required_scopes:
            raise ValueError(
                f"{persona['email']} must have one goal in each scope: "
                f"{', '.join(sorted(required_scopes))}."
            )
        if statuses != required_statuses:
            raise ValueError(
                f"{persona['email']} must have draft, approved, and active goals."
            )
        for goal in goals:
            if goal["goal_id"] in seen_goal_ids:
                raise ValueError(f"Duplicate demo goal ID: {goal['goal_id']}")
            seen_goal_ids.add(goal["goal_id"])
            if status_sub_status.get(goal["status"]) != goal["sub_status"]:
                raise ValueError(
                    f"Invalid status/sub-status for demo goal {goal['goal_id']}."
                )


def _pdf_literal(value: str) -> str:
    safe_value = value.encode("ascii", "replace").decode("ascii")
    return safe_value.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")


def _make_pdf(lines: list[str]) -> bytes:
    commands = ["BT", "/F1 18 Tf", "54 748 Td", f"({_pdf_literal(lines[0])}) Tj", "/F1 11 Tf"]
    for line in lines[1:]:
        commands.extend(("0 -28 Td", f"({_pdf_literal(line)}) Tj"))
    commands.append("ET")
    content = "\n".join(commands).encode("ascii")
    objects = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
        f"<< /Length {len(content)} >>\nstream\n".encode("ascii") + content + b"\nendstream",
    ]
    output = bytearray(b"%PDF-1.4\n")
    offsets = [0]
    for object_number, body in enumerate(objects, start=1):
        offsets.append(len(output))
        output.extend(f"{object_number} 0 obj\n".encode("ascii"))
        output.extend(body)
        output.extend(b"\nendobj\n")
    xref_offset = len(output)
    output.extend(f"xref\n0 {len(offsets)}\n".encode("ascii"))
    output.extend(b"0000000000 65535 f \n")
    for offset in offsets[1:]:
        output.extend(f"{offset:010d} 00000 n \n".encode("ascii"))
    output.extend(
        f"trailer\n<< /Size {len(offsets)} /Root 1 0 R >>\nstartxref\n{xref_offset}\n%%EOF\n".encode("ascii")
    )
    return bytes(output)


def _write_demo_pdfs(personas: list[dict]) -> None:
    PDF_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for persona in personas:
        lines = [
            "MyImpact Demo - Written Evidence",
            f"Employee: {persona['name']} ({persona['role']})",
            f"Goal: {persona['goal_title']}",
            f"Evidence: {persona['evidence_description']}",
            "Review note: Discuss scope, individual contribution, and corroborating evidence.",
        ]
        wrapped_lines = [
            wrapped
            for line in lines[1:]
            for wrapped in textwrap.wrap(line, width=82) or [""]
        ]
        pdf = _make_pdf([lines[0], *wrapped_lines])
        (PDF_OUTPUT_DIR / f"{persona['slug']}.pdf").write_bytes(pdf)


def _evidence_rows(persona: dict) -> list[dict]:
    issue_number = persona["issue_key"].rsplit("-", 1)[1]
    repository = f"myimpact-demo/{persona['slug']}-growth"
    return [
        {
            "kind": "github",
            "source_type": "GITHUB",
            "source_id": f"{repository}#{issue_number}",
            "title": persona["summary"],
            "description": persona["evidence_description"],
            "source_url": None,
            "impact_type": "TECHNICAL",
        },
        {
            "kind": "jira",
            "source_type": "JIRA",
            "source_id": persona["issue_key"],
            "title": f"{persona['issue_key']}: {persona['summary']}",
            "description": persona["evidence_description"],
            "source_url": None,
            "impact_type": "OPERATIONAL",
        },
        {
            "kind": "pdf",
            "source_type": "DOCUMENT",
            "source_id": f"{persona['slug']}.pdf",
            "title": f"Written evidence: {persona['goal_title']}",
            "description": persona["evidence_description"],
            "source_url": f"/demo-evidence/{persona['slug']}.pdf",
            "impact_type": "LEADERSHIP",
        },
    ]


def seed_demo_data(password: str, personas: list[dict]) -> None:
    _validate_seed_personas(personas)
    now = datetime.now(UTC)
    with SessionLocal() as session:
        organization_id = session.execute(
            text(
                """INSERT INTO organizations (id, name, normalized_name, created_at)
                VALUES (:id, :name, :normalized_name, :created_at)
                ON CONFLICT (normalized_name) DO UPDATE SET name = EXCLUDED.name
                RETURNING id"""
            ),
            {
                **DEMO_ORGANIZATION,
                "created_at": now,
            },
        ).scalar_one()

        for persona in personas:
            session.execute(
                text(
                    """INSERT INTO users (
                        id, name, email, role, organization_id, is_platform_admin, is_active,
                        password_hash, created_at, updated_at
                    ) VALUES (
                        :id, :name, :email, :role, :organization_id, FALSE, TRUE,
                        :password_hash, :created_at, :updated_at
                    )
                    ON CONFLICT (id) DO UPDATE SET
                        name = EXCLUDED.name, email = EXCLUDED.email, role = EXCLUDED.role,
                        organization_id = EXCLUDED.organization_id,
                        is_platform_admin = FALSE, is_active = TRUE,
                        password_hash = EXCLUDED.password_hash, updated_at = EXCLUDED.updated_at"""
                ),
                {
                    "id": persona["user_id"],
                    "name": persona["name"],
                    "email": persona["email"],
                    "role": persona["role"],
                    "organization_id": organization_id,
                    "password_hash": hash_password(password),
                    "created_at": now,
                    "updated_at": now,
                },
            )
            for goal in _goal_rows(persona):
                session.execute(
                    text(
                        """INSERT INTO goals (
                            id, user_id, title, description, scope, organization_id,
                            start_date, end_date, status, sub_status, source,
                            created_at, updated_at
                        ) VALUES (
                            :id, :user_id, :title, :description, CAST(:scope AS goal_scope),
                            :organization_id, CAST(:start_date AS date), CAST(:end_date AS date),
                            CAST(:status AS goal_status), CAST(:sub_status AS goal_sub_status),
                            :source, :created_at, :updated_at
                        ) ON CONFLICT (id) DO UPDATE SET
                            user_id = EXCLUDED.user_id, title = EXCLUDED.title,
                            description = EXCLUDED.description, scope = EXCLUDED.scope,
                            organization_id = EXCLUDED.organization_id,
                            start_date = EXCLUDED.start_date, end_date = EXCLUDED.end_date,
                            status = EXCLUDED.status, sub_status = EXCLUDED.sub_status,
                            source = EXCLUDED.source, updated_at = EXCLUDED.updated_at"""
                    ),
                    {
                        "id": goal["goal_id"],
                        "user_id": persona["user_id"],
                        "title": goal["title"],
                        "description": goal["description"],
                        "scope": goal["scope"],
                        "organization_id": (
                            organization_id if goal["scope"] == "ORGANIZATION" else None
                        ),
                        "start_date": "2026-01-01",
                        "end_date": "2026-12-31",
                        "status": goal["status"],
                        "sub_status": goal["sub_status"],
                        "source": "demo-persona-seed",
                        "created_at": now,
                        "updated_at": now,
                    },
                )

            for evidence in _evidence_rows(persona):
                evidence_id = f"evidence-demo-{persona['user_id']}-{evidence['kind']}"
                content_hash = hashlib.sha256(
                    evidence["description"].encode("utf-8")
                ).hexdigest()
                session.execute(
                    text(
                        """INSERT INTO evidence (
                            id, user_id, source_type, source_id, title, description,
                            source_url, captured_at, source_updated_at, content_hash,
                            status, created_at, updated_at
                        ) VALUES (
                            :id, :user_id, CAST(:source_type AS evidence_source_type),
                            :source_id, :title, :description, :source_url, :captured_at,
                            :source_updated_at, :content_hash,
                            CAST('ACTIVE' AS evidence_status), :created_at, :updated_at
                        ) ON CONFLICT (id) DO UPDATE SET
                            user_id = EXCLUDED.user_id, source_type = EXCLUDED.source_type,
                            source_id = EXCLUDED.source_id, title = EXCLUDED.title,
                            description = EXCLUDED.description, source_url = EXCLUDED.source_url,
                            captured_at = EXCLUDED.captured_at,
                            source_updated_at = EXCLUDED.source_updated_at,
                            content_hash = EXCLUDED.content_hash, status = EXCLUDED.status,
                            updated_at = EXCLUDED.updated_at"""
                    ),
                    {
                        "id": evidence_id,
                        "user_id": persona["user_id"],
                        "source_type": evidence["source_type"],
                        "source_id": evidence["source_id"],
                        "title": evidence["title"],
                        "description": evidence["description"],
                        "source_url": evidence["source_url"],
                        "captured_at": CAPTURED_AT,
                        "source_updated_at": CAPTURED_AT,
                        "content_hash": content_hash,
                        "created_at": now,
                        "updated_at": now,
                    },
                )
                session.execute(
                    text(
                        """INSERT INTO evidence_versions (
                            id, evidence_id, version, content, content_hash,
                            source_updated_at, captured_at, created_at
                        ) VALUES (
                            :id, :evidence_id, 1, :content, :content_hash,
                            :source_updated_at, :captured_at, :created_at
                        ) ON CONFLICT (evidence_id, version) DO UPDATE SET
                            content = EXCLUDED.content, content_hash = EXCLUDED.content_hash,
                            source_updated_at = EXCLUDED.source_updated_at,
                            captured_at = EXCLUDED.captured_at"""
                    ),
                    {
                        "id": f"version-demo-{persona['user_id']}-{evidence['kind']}",
                        "evidence_id": evidence_id,
                        "content": evidence["description"],
                        "content_hash": content_hash,
                        "source_updated_at": CAPTURED_AT,
                        "captured_at": CAPTURED_AT,
                        "created_at": now,
                    },
                )
                session.execute(
                    text(
                        """INSERT INTO evidence_mappings (
                            id, evidence_id, goal_id, relevance, reason, confidence,
                            created_at, updated_at
                        ) VALUES (
                            :id, :evidence_id, :goal_id, CAST('HIGH' AS evidence_relevance),
                            :reason, 0.88, :created_at, :updated_at
                        ) ON CONFLICT (evidence_id, goal_id) DO UPDATE SET
                            relevance = EXCLUDED.relevance, reason = EXCLUDED.reason,
                            confidence = EXCLUDED.confidence, updated_at = EXCLUDED.updated_at"""
                    ),
                    {
                        "id": f"mapping-demo-{persona['user_id']}-{evidence['kind']}",
                        "evidence_id": evidence_id,
                        "goal_id": persona["goal_id"],
                        "reason": "This sample record is associated with the persona's focus goal for impact review.",
                        "created_at": now,
                        "updated_at": now,
                    },
                )
                session.execute(
                    text(
                        """INSERT INTO impact_assessments (
                            id, evidence_id, goal_id, impact_type, impact_summary,
                            impact_score, confidence, assessment_version, created_at, updated_at
                        ) VALUES (
                            :id, :evidence_id, :goal_id, CAST(:impact_type AS impact_type),
                            :impact_summary, 0.75, 0.82, 1, :created_at, :updated_at
                        ) ON CONFLICT (id) DO UPDATE SET
                            evidence_id = EXCLUDED.evidence_id, goal_id = EXCLUDED.goal_id,
                            impact_type = EXCLUDED.impact_type,
                            impact_summary = EXCLUDED.impact_summary,
                            impact_score = EXCLUDED.impact_score, confidence = EXCLUDED.confidence,
                            assessment_version = EXCLUDED.assessment_version,
                            updated_at = EXCLUDED.updated_at"""
                    ),
                    {
                        "id": f"impact-demo-{persona['user_id']}-{evidence['kind']}",
                        "evidence_id": evidence_id,
                        "goal_id": persona["goal_id"],
                        "impact_type": evidence["impact_type"],
                        "impact_summary": evidence["description"],
                        "created_at": now,
                        "updated_at": now,
                    },
                )

        session.execute(
            text(
                """INSERT INTO users (
                    id, name, email, role, is_platform_admin, is_active,
                    password_hash, created_at, updated_at
                ) VALUES (
                    :id, :name, :email, NULL, TRUE, TRUE,
                    :password_hash, :created_at, :updated_at
                )
                ON CONFLICT (id) DO UPDATE SET
                    name = EXCLUDED.name, email = EXCLUDED.email, role = NULL,
                    is_platform_admin = TRUE, is_active = TRUE,
                    password_hash = EXCLUDED.password_hash,
                    updated_at = EXCLUDED.updated_at"""
            ),
            {
                "id": DEMO_ADMIN["user_id"],
                "name": DEMO_ADMIN["name"],
                "email": DEMO_ADMIN["email"],
                "password_hash": hash_password(password),
                "created_at": now,
                "updated_at": now,
            },
        )
        session.commit()


def _validate_seed_target() -> None:
    database_url = make_url(get_settings().database_url)
    if database_url.host not in {"localhost", "127.0.0.1", "::1", "postgres"} and os.environ.get(
        "ALLOW_REMOTE_DEMO_SEED"
    ) != "true":
        raise SystemExit(
            "Refusing to seed a non-local database without ALLOW_REMOTE_DEMO_SEED=true."
        )


def main() -> None:
    parser = argparse.ArgumentParser(description="Seed local MyImpact demo personas and evidence.")
    parser.add_argument(
        "--assets-only",
        action="store_true",
        help="Generate the demo PDFs without modifying the database.",
    )
    parser.add_argument(
        "--preflight-only",
        action="store_true",
        help="Validate the password and local database target without writing data.",
    )
    args = parser.parse_args()
    import json

    personas = json.loads(PERSONAS_PATH.read_text(encoding="utf-8"))["personas"]
    _validate_seed_personas(personas)
    if args.assets_only:
        _write_demo_pdfs(personas)
        print(f"Generated {len(personas)} demo evidence PDFs in {PDF_OUTPUT_DIR}.")
        return

    password = os.environ.get("DEMO_USER_PASSWORD", "")
    if len(password) < 12:
        raise SystemExit("Set DEMO_USER_PASSWORD to a value of at least 12 characters.")
    _validate_seed_target()
    if args.preflight_only:
        print("Demo seed preflight passed.")
        return

    _write_demo_pdfs(personas)
    seed_demo_data(password, personas)
    goal_count = sum(len(_goal_rows(persona)) for persona in personas)
    evidence_count = sum(len(_evidence_rows(persona)) for persona in personas)
    print(
        f"Seeded {len(personas)} employee demo accounts and one platform-admin account, "
        f"with {goal_count} goals, {evidence_count} evidence records, and impact assessments."
    )
    print("Use DEMO_USER_PASSWORD to sign in to any demo account.")


if __name__ == "__main__":
    main()
