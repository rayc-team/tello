using System;
using Avalonia.Controls;
using Avalonia.Interactivity;
using Avalonia.Layout;
using Avalonia.Media;

namespace ExceptionalSituations
{
    public class SeatAlreadyBookedException : Exception
    {
        public SeatAlreadyBookedException(string message) : base(message) { }
    }

    public partial class MainWindow : Window
    {
        private bool[,] seats = new bool[10, 10];
        private Button[,] buttons = new Button[10, 10];

        public MainWindow()
        {
            InitializeComponent();

            for (int r = 0; r < 10; r++)
            {
                for (int s = 0; s < 10; s++)
                {
                    Button btn = new Button();
                    btn.Content = (r + 1) + "-" + (s + 1);
                    btn.HorizontalAlignment = HorizontalAlignment.Stretch;
                    btn.VerticalAlignment = VerticalAlignment.Stretch;

                    // При клике на место в зале подставляем его номер в поля ввода.
                    int rowNum = r + 1;
                    int seatNum = s + 1;
                    btn.Click += (sender, e) =>
                    {
                        RowBox.Text = rowNum.ToString();
                        SeatBox.Text = seatNum.ToString();
                    };

                    buttons[r, s] = btn;
                    HallGrid.Children.Add(btn);
                }
            }

            UpdateHall();
        }

        // Кнопка "Забронировать".
        private void Book_Click(object? sender, RoutedEventArgs e)
        {
            ProcessSeat(true);
        }

        // Кнопка "Отменить бронь".
        private void Cancel_Click(object? sender, RoutedEventArgs e)
        {
            ProcessSeat(false);
        }

        // Общий метод для бронирования и отмены.
        private void ProcessSeat(bool isBooking)
        {
            try
            {
                // Переводим текст из полей ввода в числа.
                int row = int.Parse(RowBox.Text ?? "");
                int seat = int.Parse(SeatBox.Text ?? "");

                // Если ряд меньше 1 или больше 10.
                if (row < 1 || row > 10)
                {
                    throw new ArgumentException("Некорректный ряд. Введите число от 1 до 10.");
                }

                // Если место меньше 1 или больше 10.
                if (seat < 1 || seat > 10)
                {
                    throw new IndexOutOfRangeException("Неверный номер места. Введите число от 1 до 10.");
                }

                int r = row - 1;
                int s = seat - 1;

                if (isBooking)
                {
                    if (seats[r, s] == true)
                    {
                        throw new SeatAlreadyBookedException("Это место уже забронировано.");
                    }

                    seats[r, s] = true;
                    StatusText.Text = "Операция прошла успешно: место забронировано.";
                }
                else
                {
                    if (seats[r, s] == false)
                    {
                        throw new SeatAlreadyBookedException("Это место и так свободно, отменять нечего.");
                    }

                    seats[r, s] = false;
                    StatusText.Text = "Операция прошла успешно: бронь отменена.";
                }
            }
            // Обработка ошибки, если ввели текст вместо цифр.
            catch (FormatException)
            {
                StatusText.Text = "Операция не прошла: введите числа в поля ряда и места.";
            }
            // Обработка ошибки неправильного ряда.
            catch (ArgumentException ex)
            {
                StatusText.Text = "Операция не прошла: " + ex.Message;
            }
            // Обработка ошибки неправильного места.
            catch (IndexOutOfRangeException ex)
            {
                StatusText.Text = "Операция не прошла: " + ex.Message;
            }
            // Обработка нашей ошибки бронирования.
            catch (SeatAlreadyBookedException ex)
            {
                StatusText.Text = "Операция не прошла: " + ex.Message;
            }
            // Обработка любых других ошибок.
            catch (Exception ex)
            {
                StatusText.Text = "Операция не прошла: " + ex.Message;
            }
            //! Перерисовываем зал и обновляем статистику.
            finally
            {
                UpdateHall();
            }
        }

        // Перерисовка цветов кнопок и подсчет статистики.
        private void UpdateHall()
        {
            int free = 0;
            int booked = 0;

            for (int r = 0; r < 10; r++)
            {
                for (int s = 0; s < 10; s++)
                {
                    if (seats[r, s] == true)
                    {
                        buttons[r, s].Background = Brushes.LightCoral;
                        booked++;
                    }
                    else
                    {
                        buttons[r, s].Background = Brushes.LightGreen;
                        free++;
                    }
                }
            }

            StatsText.Text = $"Свободно: {free} | Занято: {booked}";
        }
    }
}
