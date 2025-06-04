#!/usr/bin/env python3
import threading
import serial
import time
import curses
import re
import serial.tools.list_ports

BAUD = 9600
MAX_LOG_LINES = 20

# regex pattern per ciascuna riga
patterns = {
    'last':  re.compile(r'LC:\s*(.*)$'),
    'soa':   re.compile(r'ISOA:\s*(.*)$'),
    'ctll':  re.compile(r'CTLL:\s*(.*)$'),
    'ctlh':  re.compile(r'CTLH:\s*(.*)$'),
    'mode':  re.compile(r'MODE:\s*(.*)$'),
    'tecv':  re.compile(r'TECV:\s*(.*)$'),
    'dc':    re.compile(r'DC:\s*(.*)$'),
    'setp':  re.compile(r'SETP:\s*(.*)$')
}

# Funzione per la selezione manuale della porta
def select_serial_port():
    ports = list(serial.tools.list_ports.comports())
    if not ports:
        print("Nessuna porta seriale trovata.")
        exit(1)

    print("Seleziona la porta seriale:")
    for i, p in enumerate(ports):
        print(f"  [{i}] {p.device} — {p.description}")

    while True:
        try:
            choice = int(input("Numero > "))
            if 0 <= choice < len(ports):
                return ports[choice].device
        except ValueError:
            pass
        print("Input non valido, riprova.")

# Thread di lettura dalla seriale
def reader_thread(ser, state, lock, log_lines):
    buffer = bytearray()

    while True:
        try:
            data = ser.read(64)  # Leggi fino a 64 byte in un colpo
            if not data:
                continue

            buffer.extend(data)

            # Finché c'è un newline, estraiamo righe complete
            while b'\n' in buffer:
                line_bytes, sep, buffer = buffer.partition(b'\n')
                # Rimuoviamo tutti i caratteri nulli (\x00)
                filtered = bytes(b for b in line_bytes if b != 0)

                # Decodifichiamo e invertiamo la stringa per ripristinare l'ordine corretto
                try:
                    decoded_line = filtered.decode('ascii', errors='ignore').strip()
                    decoded_line = decoded_line[::-1]  # <-- qui invertiamo
                except Exception:
                    decoded_line = ''

                if decoded_line:
                    with lock:
                        log_lines.append(decoded_line)
                        if len(log_lines) > MAX_LOG_LINES:
                            log_lines.pop(0)

                    # Proviamo a matchare i pattern su decoded_line
                    for key, regex in patterns.items():
                        match = regex.match(decoded_line)
                        if match:
                            with lock:
                                state[key] = match.group(1)
                            break

        except Exception as e:
            with lock:
                log_lines.append(f"[Errore lettura]: {e}")
                if len(log_lines) > MAX_LOG_LINES:
                    log_lines.pop(0)

# Funzione principale curses
def curses_main(stdscr, ser):
    curses.curs_set(1)
    stdscr.nodelay(True)
    stdscr.timeout(100)

    state = {key: '' for key in patterns}
    lock = threading.Lock()
    log_lines = []

    t = threading.Thread(target=reader_thread, args=(ser, state, lock, log_lines), daemon=True)
    t.start()

    input_buf = ''
    max_y, max_x = stdscr.getmaxyx()

    while True:
        stdscr.erase()

        base = 0
        with lock:
            # Mostriamo i valori correnti di state
            for i, key in enumerate(state):
                stdscr.addstr(base + i, 0, f"{key.upper()}: {state[key]}")
            stdscr.addstr(base + len(state) + 1, 0, "Log RAW (stream in ingresso):")
            # Mostriamo fino a MAX_LOG_LINES di log_lines
            for i, line in enumerate(log_lines):
                y = base + len(state) + 2 + i
                if y < max_y - 2:
                    stdscr.addstr(y, 0, line[:max_x - 1])

        prompt = "Command> " + input_buf
        stdscr.addstr(max_y - 1, 0, prompt[:max_x - 1])
        stdscr.move(max_y - 1, len("Command> ") + len(input_buf))
        stdscr.refresh()

        try:
            ch = stdscr.get_wch()
        except curses.error:
            ch = None

        if ch is None:
            continue
        elif isinstance(ch, str) and ch.isprintable():
            input_buf += ch
        elif ch == '\n':
            ser.write((input_buf).encode('ascii') + b'\n')
            input_buf = ''
        elif ch in (curses.KEY_BACKSPACE, '\b', '\x7f'):
            input_buf = input_buf[:-1]
        elif ch in (curses.KEY_EXIT, '\x03'):
            break

    ser.close()

# Entry point
if __name__ == '__main__':
    port = select_serial_port()
    try:
        ser = serial.Serial(
            port,
            baudrate=BAUD,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=1
        )
    except Exception as e:
        print(f"Errore nell'apertura della porta seriale: {e}")
        exit(1)

    curses.wrapper(curses_main, ser)
