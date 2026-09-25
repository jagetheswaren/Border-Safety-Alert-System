"""Persist idempotent, owned safety events."""
from alembic import op
import sqlalchemy as sa

revision = '002_safety_events'
down_revision = '001_postgis'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table('safety_events',
        sa.Column('event_id', sa.String(), primary_key=True),
        sa.Column('device_id', sa.String(), sa.ForeignKey('devices.id'), nullable=False),
        sa.Column('user_id', sa.String(), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('payload_json', sa.Text(), nullable=False),
        sa.Column('payload_sha256', sa.String(64), nullable=False),
        sa.Column('captured_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('received_at', sa.DateTime(timezone=True), server_default=sa.func.now()))
    op.create_index('ix_safety_events_device_id', 'safety_events', ['device_id'])
    op.create_index('ix_safety_events_user_id', 'safety_events', ['user_id'])


def downgrade():
    op.drop_table('safety_events')
