from pydantic import BaseModel, Field, AwareDatetime, model_validator
from typing import Literal
from datetime import datetime

class SafetyEventSyncItem(BaseModel):
    event_id: str = Field(min_length=1, max_length=128)
    timestamp: AwareDatetime
    event_type: str = Field(max_length=80)
    latitude: float = Field(ge=-90, le=90, allow_inf_nan=False)
    longitude: float = Field(ge=-180, le=180, allow_inf_nan=False)
    zone: str = Field(max_length=256)
    risk_state: str = Field(max_length=48)
    ai_state: str = Field(max_length=48)
    alert_state: str = Field(max_length=256)
    device_id: str | None = None

class SyncBatchRequest(BaseModel):
    device_id: str = Field(min_length=1, max_length=128)
    client_timestamp: AwareDatetime | None = None
    events: list[SafetyEventSyncItem] = Field(default_factory=list, max_length=100)

    @model_validator(mode='after')
    def validate_batch(self):
        if len({e.event_id for e in self.events}) != len(self.events):
            raise ValueError('Duplicate event IDs in batch')
        if any(e.device_id and e.device_id != self.device_id for e in self.events):
            raise ValueError('Event device does not match batch device')
        return self

class SyncBatchResponse(BaseModel):
    status: Literal['SUCCESS'] = 'SUCCESS'
    synced_count: int
    acknowledged_ids: list[str]
    receipt_id: str
    server_timestamp: datetime
