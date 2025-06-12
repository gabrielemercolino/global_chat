defmodule JustChat.Rooms do
  def validate_room_name(""), do: :empty

  def validate_room_name(name) when byte_size(name) > 30, do: :too_long

  def validate_room_name(name) do
    if Regex.match?(~r/^[a-zA-Z0-9_-]+$/, name) do
      :ok
    else
      :invalid_characters
    end
  end
end
