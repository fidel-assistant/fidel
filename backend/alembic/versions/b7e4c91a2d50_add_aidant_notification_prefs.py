"""add_aidant_notification_prefs

Revision ID: b7e4c91a2d50
Revises: f8a1c62d9e30
Create Date: 2026-09-20 09:15:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

from alembic import op

revision: str = "b7e4c91a2d50"
down_revision: str | None = "f8a1c62d9e30"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "patient_aidant",
        sa.Column(
            "notification_prefs",
            JSONB(astext_type=sa.Text()),
            nullable=False,
            server_default=sa.text("'{}'::jsonb"),
        ),
    )


def downgrade() -> None:
    op.drop_column("patient_aidant", "notification_prefs")
