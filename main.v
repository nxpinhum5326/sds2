import gg
import gx
import os

struct App {
mut:
    ctx &gg.Context = unsafe { nil }
    apps []SubApp
    files map[string]File
}

struct SubApp {
    x int
    y int
    width int
    height int
    color gx.Color
    title string
    notes_per_page int = 10
mut:
    widgets []Widget
    input string
    notes []string
    file string
    current_page int
}

struct Widget {
    x int
    y int
    width int
    height int
    color gx.Color
}

struct File {
mut:
    main_lines []string
    sects map[string][]string
}

fn (mut a App) create_context() {
    a.ctx = gg.new_context(
        bg_color: gx.rgb(174, 198, 255)
        width: 544
        height: 560
        window_title: "SDS2 Test Version"
        frame_fn: frame
        event_fn: event_handler
        user_data: a
    )

    a.init_sub_apps()
}

fn (mut a App) init_sub_apps() {
    a.apps << SubApp{
        x: 10
        y: 50
        width: 250
        height: 500
        color: gx.rgb(255, 255, 255)
        title: "Write Note"
        file: "notes.txt"
    }
    
    a.apps << SubApp{
        x: 270
        y: 50
        width: 250
        height: 500
        color: gx.rgb(255, 255, 255)
        title: "Available Notes"
        file: "notes.txt"
    }

    if !os.exists("notes.txt") {
        os.write_file("notes.txt", "") or { panic(err) }
    }

    for mut subapp in a.apps {
        subapp.notes = os.read_lines(subapp.file) or { []string{} }
    }
}

fn (mut a App) render() {
    for mut app in a.apps {
        a.ctx.draw_rect_filled(app.x, app.y, app.width, app.height, app.color)
        a.ctx.draw_text(app.x + 10, app.y + 10, app.title, gx.TextCfg {
            color: gx.black
            size: 16
        })

        if app.title == "Write Note" {
            a.ctx.draw_text(app.x + 10, app.y + 50, "Input: ${app.input}", gx.TextCfg {
                color: gx.black
                size: 14
            })
        } else if app.title == "Available Notes" {
            mut y_offset := 50
            start_idx := app.current_page * app.notes_per_page
            mut end_idx := start_idx + app.notes_per_page

            if start_idx >= app.notes.len {
                continue
            }

            end_idx = if end_idx > app.notes.len { app.notes.len } else { end_idx }
            paginated_notes := app.notes[start_idx..end_idx]

            for note in paginated_notes {
                a.ctx.draw_text(app.x + 10, app.y + y_offset, note, gx.TextCfg {
                    color: gx.black
                    size: 14
                })
                y_offset += 20
            }

            a.ctx.draw_text(app.x + 10, app.y + 470, "Previous", gx.TextCfg {
                color: if app.current_page > 0 { gx.blue } else { gx.gray }
                size: 14
            })
            a.ctx.draw_text(app.x + 150, app.y + 470, "Next", gx.TextCfg {
                color: if (app.current_page + 1) * app.notes_per_page < app.notes.len { gx.blue } else { gx.gray }
                size: 14
            })
        }
    }
}

fn frame(mut a App) {
    a.ctx.begin()
    a.render()
    a.ctx.end()
}

fn event_handler(e &gg.Event, mut a App) {
    for mut app in a.apps {
        if app.title == "Write Note" {
            if e.typ == .char {
                app.input += utf32_to_str(e.char_code)
            } else if e.key_code == gg.KeyCode.enter {
                if app.input.len > 0 {
                    app.notes << app.input
                    os.write_file(app.file, app.notes.join('\n')) or { panic(err) }
                    app.input = ""

                    for mut subapp in a.apps {
                        if subapp.title == "Available Notes" {
                            subapp.notes = os.read_lines(subapp.file) or { []string{} }
                        }
                    }
                }
            } else if e.key_code == gg.KeyCode.backspace {
                if app.input.len > 0 {
                    app.input = app.input[..app.input.len - 1]
                }
            }
        } else if app.title == "Available Notes" {
           if e.typ == .key_down {
                if e.key_code == gg.KeyCode.left {
                    if app.current_page > 0 {
                        app.current_page--
                    }
                } else if e.key_code == gg.KeyCode.right {
                    if (app.current_page + 1) * app.notes_per_page < app.notes.len {
                        app.current_page++
                    }
                }
            }
        }
    }
}

fn (mut a App) run() {
    a.ctx.run()
}

fn main() {
    mut app := App{}
    app.create_context()
    app.run()
}
