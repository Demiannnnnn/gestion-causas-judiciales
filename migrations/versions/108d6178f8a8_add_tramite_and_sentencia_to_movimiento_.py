"""Add TRAMITE and SENTENCIA to Movimiento.tipo enum manually

Revision ID: 108d6178f8a8
Revises: 233e8897dfc4
Create Date: 2025-11-10 21:20:34.187739

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '108d6178f8a8'
down_revision: Union[str, None] = '233e8897dfc4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("ALTER TABLE Movimiento MODIFY COLUMN tipo ENUM('AUDIENCIA', 'RESOLUCIÓN', 'SUSPENSIÓN', 'VENCIMIENTO', 'OTRO', 'TRAMITE', 'SENTENCIA') NOT NULL")


def downgrade() -> None:
    op.execute("ALTER TABLE Movimiento MODIFY COLUMN tipo ENUM('AUDIENCIA', 'RESOLUCIÓN', 'SUSPENSIÓN', 'VENCIMIENTO', 'OTRO') NOT NULL")
