#!/usr/bin/env python3
import os
import datetime
import json
import sys
from typing import Optional
import caldav
from mcp.server.fastmcp import FastMCP

# Configuration
BASE_URL = "https://nx16614.your-storageshare.de/remote.php/dav"
USERNAME = os.environ.get("CALDAV_USERNAME", "agent")
PASSWORD = os.environ.get("CALDAV_PASSWORD") or os.environ.get("NEXTCLOUD_APP_PASSWORD")

mcp = FastMCP("CalDAV Pinned")

def get_client():
    if not PASSWORD:
        raise ValueError("CALDAV_PASSWORD or NEXTCLOUD_APP_PASSWORD must be set")
    return caldav.DAVClient(url=BASE_URL, username=USERNAME, password=PASSWORD)

def get_target_calendar(client, calendar_url: Optional[str] = None):
    if calendar_url:
        return client.calendar(url=calendar_url)
    
    personal_url = f"{BASE_URL}/calendars/{USERNAME}/personal/"
    try:
        calendar = client.calendar(url=personal_url)
        calendar.get_display_name()
        return calendar
    except:
        principal = client.principal()
        calendars = principal.calendars()
        for cal in calendars:
            url_lower = str(cal.url).lower()
            if "personal" in url_lower:
                return cal
        return calendars[0] if calendars else None

@mcp.tool()
def list_calendars() -> str:
    """List all available calendars with their URLs."""
    try:
        client = get_client()
        principal = client.principal()
        calendars = principal.calendars()
        
        result = []
        for cal in calendars:
            result.append(f"- {cal.get_display_name()}: {cal.url}")
        return "\n".join(result)
    except Exception as e:
        return f"Error listing calendars: {e}"

@mcp.tool()
def list_events(start: str, end: str, calendar_url: Optional[str] = None) -> str:
    """
    List events between start and end date.
    Dates should be in ISO 8601 format.
    """
    try:
        client = get_client()
        calendar = get_target_calendar(client, calendar_url)
        if not calendar:
            return "No calendar found."
            
        start_dt = datetime.datetime.fromisoformat(start.replace("Z", "+00:00"))
        end_dt = datetime.datetime.fromisoformat(end.replace("Z", "+00:00"))
        
        # Format dates for CalDAV XML (YYYYMMDDTHHMMSSZ)
        start_str = start_dt.strftime("%Y%m%dT%H%M%SZ")
        end_str = end_dt.strftime("%Y%m%dT%H%M%SZ")

        # Construct raw XML to ensure correct nesting of time-range filter
        # SabreDAV (Nextcloud) requires time-range to be inside VEVENT
        xml = f"""
<c:calendar-query xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
    <d:prop>
        <d:getetag/>
        <c:calendar-data/>
    </d:prop>
    <c:filter>
        <c:comp-filter name="VCALENDAR">
            <c:comp-filter name="VEVENT">
                <c:time-range start="{start_str}" end="{end_str}"/>
            </c:comp-filter>
        </c:comp-filter>
    </c:filter>
</c:calendar-query>
"""
        events = calendar.search(xml=xml)
        
        output = []
        for event in events:
            vevent = event.vobject_instance.vevent
            uid = getattr(vevent, 'uid', None)
            summary = getattr(vevent, 'summary', None)
            dtstart = getattr(vevent, 'dtstart', None)
            dtend = getattr(vevent, 'dtend', None)
            
            output.append({
                "uid": uid.value if uid else "N/A",
                "summary": summary.value if summary else "Untitled",
                "start": dtstart.value.isoformat() if dtstart else "N/A",
                "end": dtend.value.isoformat() if dtend else "N/A"
            })
        
        return json.dumps(output, indent=2)
    except Exception as e:
        return f"Error listing events: {e}"

@mcp.tool()
def create_event(summary: str, start: str, end: str, description: Optional[str] = None, calendar_url: Optional[str] = None) -> str:
    """Create a new event."""
    try:
        client = get_client()
        calendar = get_target_calendar(client, calendar_url)
        if not calendar:
            return "No calendar found."
            
        start_dt = datetime.datetime.fromisoformat(start.replace("Z", "+00:00"))
        end_dt = datetime.datetime.fromisoformat(end.replace("Z", "+00:00"))
        
        event = calendar.save_event(
            dtstart=start_dt,
            dtend=end_dt,
            summary=summary,
            description=description
        )
        return f"Event created: {event.url}"
    except Exception as e:
        return f"Error creating event: {e}"

@mcp.tool()
def delete_event(uid: str, calendar_url: Optional[str] = None) -> str:
    """Delete an event by its UID."""
    try:
        client = get_client()
        calendar = get_target_calendar(client, calendar_url)
        if not calendar:
            return "No calendar found."
            
        event = calendar.event_by_uid(uid)
        event.delete()
        return f"Event with UID {uid} deleted."
    except Exception as e:
        return f"Error deleting event: {e}"

if __name__ == "__main__":
    mcp.run()
