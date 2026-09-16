const MEAL_LABELS = {
  breakfast: 'Desayuno',
  lunch: 'Comida',
  dinner: 'Cena',
}

function escapeText(value) {
  return String(value || '')
    .replace(/\\/g, '\\\\')
    .replace(/;/g, '\\;')
    .replace(/,/g, '\\,')
    .replace(/\r?\n/g, '\\n')
}

function foldLine(line) {
  const characters = Array.from(line)
  const parts = []
  for (let index = 0; index < characters.length; index += 74) {
    parts.push((index ? ' ' : '') + characters.slice(index, index + 74).join(''))
  }
  return parts.join('\r\n')
}

function dateParts(isoDate) {
  return isoDate.replaceAll('-', '')
}

function localIsoDate(date) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
}

function nextDate(isoDate) {
  const date = new Date(`${isoDate}T00:00:00`)
  date.setDate(date.getDate() + 1)
  return `${date.getFullYear()}${String(date.getMonth() + 1).padStart(2, '0')}${String(date.getDate()).padStart(2, '0')}`
}

function timedDate(isoDate, time) {
  return `${dateParts(isoDate)}T${time.replace(':', '')}00`
}

function eventDescription(day, meal) {
  const parts = []
  if (meal.note?.trim()) parts.push(`Nota de la comida: ${meal.note.trim()}`)
  if (day.notes?.trim()) parts.push(`Nota del día: ${day.notes.trim()}`)
  return parts.join('\n')
}

function eventLines({ uid, date, meal, time, day }) {
  const items = (meal.items || [])
    .filter((item) => String(item).trim())
    .map((item) => String(item).trim())
  if (!items.length || day.skipped || meal.skipped) return []

  const label = MEAL_LABELS[meal.slot] || 'Comida'
  const summary = `${label}: ${items.join(', ')}`
  const description = eventDescription(day, meal)
  const lines = [
    'BEGIN:VEVENT',
    `UID:${escapeText(`${uid}-${date}-${meal.slot}@menudiario.alon.one`)}`,
    `DTSTAMP:${new Date()
      .toISOString()
      .replace(/[-:]/g, '')
      .replace(/\.\d{3}Z$/, 'Z')}`,
  ]

  if (time) {
    lines.push(`DTSTART;TZID=Europe/Madrid:${timedDate(date, time)}`)
    const [hours, minutes] = time.split(':').map(Number)
    const end = new Date(
      `${date}T${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:00`,
    )
    end.setHours(end.getHours() + 1)
    const endTime = `${String(end.getHours()).padStart(2, '0')}:${String(end.getMinutes()).padStart(2, '0')}`
    lines.push(`DTEND;TZID=Europe/Madrid:${timedDate(localIsoDate(end), endTime)}`)
  } else {
    lines.push(`DTSTART;VALUE=DATE:${dateParts(date)}`)
    lines.push(`DTEND;VALUE=DATE:${nextDate(date)}`)
  }

  lines.push(`SUMMARY:${escapeText(summary)}`)
  if (description) lines.push(`DESCRIPTION:${escapeText(description)}`)
  lines.push(`CATEGORIES:${escapeText(label)}`, 'END:VEVENT')
  return lines
}

export function buildMealCalendar({ uid, days, times = {} }) {
  const lines = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Menu Diario//Calendario de comidas//ES',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    'X-WR-CALNAME:Menu Diario',
    'X-WR-TIMEZONE:Europe/Madrid',
  ]

  Object.entries(days || {})
    .sort(([first], [second]) => first.localeCompare(second))
    .forEach(([date, day]) => {
      const slots = ['breakfast', 'lunch', 'dinner']
      slots.forEach((slot) => {
        const sourceMeal = day?.meals?.[slot]
        if (!sourceMeal) return
        lines.push(
          ...eventLines({
            uid,
            date,
            day,
            time: times[slot] || '',
            meal: { ...sourceMeal, slot },
          }),
        )
      })
    })

  lines.push('END:VCALENDAR')
  return `${lines.map(foldLine).join('\r\n')}\r\n`
}
