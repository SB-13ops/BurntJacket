"""Rename waxstack_score -> burntjacket_score (in place, data-preserving).

Part of the Burnt Jacket rebrand. This ALTERs the column name without touching
data, mirroring the earlier dead_wax_score -> waxstack_score rename.
"""
from alembic import op

revision = "0010_rename_score_burntjacket"
down_revision = "0009_value_tracking"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.alter_column("hunt_results", "waxstack_score", new_column_name="burntjacket_score")


def downgrade() -> None:
    op.alter_column("hunt_results", "burntjacket_score", new_column_name="waxstack_score")
