"""001_initial_postgis_schema

Revision ID: 001_postgis
Revises: 
Create Date: 2026-09-25 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from geoalchemy2 import Geometry

revision = '001_postgis'
down_revision = None
branch_labels = None
depends_on = None

def upgrade() -> None:
    # 1. Enable PostGIS
    op.execute("CREATE EXTENSION IF NOT EXISTS postgis;")

    # 2. Users table
    op.create_table(
        'users',
        sa.Column('id', sa.String(), primary_key=True),
        sa.Column('email', sa.String(), nullable=False, unique=True, index=True),
        sa.Column('hashed_password', sa.String(), nullable=False),
        sa.Column('role', sa.String(), nullable=False, server_default='FIELD_USER'),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    # 3. Zones table with PostGIS Polygon geometry
    op.create_table(
        'zones',
        sa.Column('id', sa.String(), primary_key=True),
        sa.Column('name', sa.String(), nullable=False, index=True),
        sa.Column('type', sa.String(), nullable=False),
        sa.Column('severity', sa.String(), nullable=False),
        sa.Column('geometry', sa.Text(), nullable=False),
        sa.Column('geom', Geometry(geometry_type='POLYGON', srid=4326, spatial_index=True), nullable=True),
        sa.Column('warning_radius_m', sa.Float(), nullable=True, server_default='0.0'),
        sa.Column('enabled', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('version', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), onupdate=sa.func.now()),
    )

    # 4. Devices table
    op.create_table(
        'devices',
        sa.Column('id', sa.String(), primary_key=True),
        sa.Column('user_id', sa.String(), sa.ForeignKey('users.id'), nullable=True),
        sa.Column('device_identifier', sa.String(), nullable=False, unique=True, index=True),
        sa.Column('device_model', sa.String(), nullable=True),
        sa.Column('os_version', sa.String(), nullable=True),
        sa.Column('app_version', sa.String(), nullable=True),
        sa.Column('last_seen', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    # 5. Incidents table with PostGIS Point geometry
    op.create_table(
        'incidents',
        sa.Column('id', sa.String(), primary_key=True),
        sa.Column('incident_number', sa.String(), nullable=False, unique=True, index=True),
        sa.Column('title', sa.String(), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('category', sa.String(), nullable=False),
        sa.Column('severity', sa.String(), nullable=False),
        sa.Column('status', sa.String(), nullable=False, server_default='OPEN'),
        sa.Column('latitude', sa.Float(), nullable=False),
        sa.Column('longitude', sa.Float(), nullable=False),
        sa.Column('geom', Geometry(geometry_type='POINT', srid=4326, spatial_index=True), nullable=True),
        sa.Column('zone_id', sa.String(), sa.ForeignKey('zones.id'), nullable=True),
        sa.Column('reported_by', sa.String(), nullable=True),
        sa.Column('assigned_to', sa.String(), nullable=True),
        sa.Column('ai_summary', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), onupdate=sa.func.now()),
        sa.Column('resolved_at', sa.DateTime(timezone=True), nullable=True),
    )

    # 6. Alerts table with PostGIS Point geometry
    op.create_table(
        'alerts',
        sa.Column('id', sa.String(), primary_key=True),
        sa.Column('type', sa.String(), nullable=False),
        sa.Column('severity', sa.String(), nullable=False),
        sa.Column('title', sa.String(), nullable=False),
        sa.Column('message', sa.String(), nullable=False),
        sa.Column('user_id', sa.String(), sa.ForeignKey('users.id'), nullable=True),
        sa.Column('device_id', sa.String(), nullable=True),
        sa.Column('zone_id', sa.String(), sa.ForeignKey('zones.id'), nullable=True),
        sa.Column('incident_id', sa.String(), sa.ForeignKey('incidents.id'), nullable=True),
        sa.Column('location_lat', sa.Float(), nullable=True),
        sa.Column('location_lng', sa.Float(), nullable=True),
        sa.Column('geom', Geometry(geometry_type='POINT', srid=4326, spatial_index=True), nullable=True),
        sa.Column('acknowledged', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('synced', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('acknowledged_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('resolved_at', sa.DateTime(timezone=True), nullable=True),
    )

    # 7. Location breadcrumbs table
    op.create_table(
        'location_breadcrumbs',
        sa.Column('id', sa.String(), primary_key=True),
        sa.Column('device_id', sa.String(), sa.ForeignKey('devices.id'), nullable=True),
        sa.Column('user_id', sa.String(), sa.ForeignKey('users.id'), nullable=True),
        sa.Column('timestamp', sa.DateTime(timezone=True), nullable=False, index=True),
        sa.Column('latitude', sa.Float(), nullable=False),
        sa.Column('longitude', sa.Float(), nullable=False),
        sa.Column('geom', Geometry(geometry_type='POINT', srid=4326, spatial_index=True), nullable=True),
        sa.Column('accuracy', sa.Float(), nullable=True),
        sa.Column('altitude', sa.Float(), nullable=True),
        sa.Column('speed', sa.Float(), nullable=True),
        sa.Column('bearing', sa.Float(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    # 8. Sync receipts table
    op.create_table(
        'sync_receipts',
        sa.Column('id', sa.String(), primary_key=True),
        sa.Column('device_id', sa.String(), nullable=True),
        sa.Column('user_id', sa.String(), sa.ForeignKey('users.id'), nullable=True),
        sa.Column('batch_size', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('synced_events_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('status', sa.String(), nullable=False, server_default='SUCCESS'),
        sa.Column('client_timestamp', sa.DateTime(timezone=True), nullable=True),
        sa.Column('server_timestamp', sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    # 9. Audit logs table
    op.create_table(
        'audit_logs',
        sa.Column('id', sa.String(), primary_key=True),
        sa.Column('user_id', sa.String(), sa.ForeignKey('users.id'), nullable=True),
        sa.Column('action', sa.String(), nullable=False, index=True),
        sa.Column('resource', sa.String(), nullable=True),
        sa.Column('details', sa.Text(), nullable=True),
        sa.Column('ip_address', sa.String(), nullable=True),
        sa.Column('timestamp', sa.DateTime(timezone=True), server_default=sa.func.now(), index=True),
    )

def downgrade() -> None:
    op.drop_table('audit_logs')
    op.drop_table('sync_receipts')
    op.drop_table('location_breadcrumbs')
    op.drop_table('alerts')
    op.drop_table('incidents')
    op.drop_table('devices')
    op.drop_table('zones')
    op.drop_table('users')
