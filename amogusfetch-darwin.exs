defmodule AmogusFetchDarwin do
  def main do
    {args, _, _,} =
      System.argv()
      |> OptionParser.parse(
        aliases: [b: :body_color, w: :window_color],
        strict: [body_color: :string, window_color: :string]
      )
    Enum.zip(picture(args[:body_color], args[:window_color]), values())
    |> Enum.map(fn {x, y} -> x <> String.duplicate(" ", 5) <> y end)
    |> IO.puts()
  end

  defp term, do: System.get_env("TERM") |> String.downcase()
  defp shell, do: System.get_env("SHELL") |> String.downcase()
  defp picture(fir, sec) do
    [fir, sec] = Enum.map([fir, sec], &String.to_atom(to_string(&1)))

    colors =
      Enum.zip(
        ["gray", "red", "green", "yellow", "blue", "violet", "light_blue", "white"],
        30..37
      )
      |> Enum.map(fn {x, y} -> {String.to_atom(x), y} end)

    win = "\x1b[#{colors[sec]}m"
    clear = "\x1b[0m"
    body = "\x1b[#{colors[fir]}m"

    [
      "      #{body}.mmmmmmmmmmmmmmm.#{clear}        ",
      " #{win}.+oooooooooooo+.#{clear}#{body}     'm.#{clear}      ",
      "#{win}oooooooooooooooooo#{clear}#{body}       mmmmm.#{clear}",
      "#{win}oooooooooooooooooo#{clear}#{body}       m::::m#{clear}",
      " #{win}'+oooooooooooo+'#{clear}#{body}        m::::m#{clear}",
      "     #{body}m                   m::::m#{clear}",
      "     #{body}m   +mmmmmmm.       mmmmm'#{clear}",
      "     #{body}m    'm     'm      m#{clear}     ",
      "     #{body}.mmmm.#{clear}        #{body}.mmmm.#{clear}      "
    ]
  end

  defp colors do
    Enum.map(1..7, fn x -> "\x1b[#{40 + x}m   \x1b[0m" end)
    |> List.to_string()
  end

  defp user do
    System.cmd("whoami", [])
    |> elem(0)
    |> String.trim()
  end

  defp hostname do
    System.cmd("hostname", [])
    |> elem(0)
    |> String.trim()
  end

  defp sysctl(key) do
    {output, 0} = System.cmd("sysctl", ["-n", key])
    String.trim(output)
  end

  defp uptime do
    System.cmd("uptime", [])
    |> elem(0)
    |> String.split("up")
    |> List.last()
    |> String.split(",")
    |> hd()
    |> String.trim()
  end
  defp os do
    System.cmd("sw_vers", ["--productVersion"])
    |> elem(0)
    |> String.trim()
  end

  defp kernel do
    "#{_kernel_name()} #{_kernel_version()}"
  end

  defp _kernel_name do
    sysctl("kern.ostype")
  end

  defp _kernel_version do
    sysctl("kern.osversion")
  end

  def mem() do
    {output, 0} = System.cmd("vm_stat", [])
    active_pages =
      Regex.run(~r/Pages active:\s+(\d+)/, output, capture: :all_but_first)
      |> List.first()
      |> String.to_integer()
    wired_pages =
      Regex.run(~r/Pages wired down:\s+(\d+)/, output, capture: :all_but_first)
      |> List.first()
      |> String.to_integer()

    used_mem = (active_pages + wired_pages) * 4096 |> div(1_048_576)

    total_mem = sysctl("hw.memsize") |> String.to_integer() |> div(1_048_576)
    "#{used_mem}M/#{total_mem}M"
  end

  defp cpu() do
    brand = sysctl("machdep.cpu.brand_string")
    cores = sysctl("machdep.cpu.core_count")
    threads = sysctl("machdep.cpu.thread_count")

    "#{brand} #{cores}c/#{threads}t"
  end

  defp values do
    clear = "\x1b[0m"
    bold = "\x1b[1m"

    [
      "#{bold}#{user()}@#{hostname()}#{clear}\n",
      "os: macOS #{os()}\n",
      "kernel: #{kernel()}\n",
      "mem: #{mem()}\n",
      "cpu: #{cpu()}\n",
      "uptime: #{uptime()}\n",
      "shell: #{shell()}\n",
      "term: #{term()}\n",
      "#{colors()}"
    ]
  end

end

AmogusFetchDarwin.main()
