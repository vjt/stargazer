/*
* setSerialSignal v0.1 9/13/01
* www.embeddedlinuxinterfacing.com
*
*
* The original location of this source is
* http://www.embeddedlinuxinterfacing.com/chapters/06/setSerialSignal.c
*
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU Library General Public License as
* published by the Free Software Foundation; either version 2 of the
* License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful, but
* WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
* Library General Public License for more details.
*
* You should have received a copy of the GNU Library General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc.,
* 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*/
/* setSerialSignal
* setSerialSignal sets the DTR and RTS serial port control signals.
* This program queries the serial port status then sets or clears
* the DTR or RTS bits based on user supplied command line setting.
*
* setSerialSignal clears the HUPCL bit. With the HUPCL bit set,
* when you close the serial port, the Linux serial port driver
* will drop DTR (assertion level 1, negative RS-232 voltage). By
* clearing the HUPCL bit, the serial port driver leaves the
* assertion level of DTR alone when the port is closed.
*/

/*
gcc -o setSerialSignal setSerialSignal.c
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
#include <sys/ioctl.h>

/* we need a termios structure to clear the HUPCL bit */
struct termios tio;

int main(int argc, char *argv[])
{
  int fd;
  int status;

  if (argc != 4)
    {
      printf("Usage: setSerialSignal port                  DTR RTS\n");
      printf("Usage: setSerialSignal /dev/ttyS0|/dev/ttyS1 0|1 0|1\n");
      exit( 1 );
    }

  if ((fd = open(argv[1], O_RDWR)) < 0)
    {
      printf("Couldn't open %s\n",argv[1]);
      exit(1);
    }
  tcgetattr(fd, &tio);          /* get the termio information */
  tio.c_cflag &= ~HUPCL;        /* clear the HUPCL bit */
  tcsetattr(fd, TCSANOW, &tio); /* set the termio information */

  ioctl(fd, TIOCMGET, &status); /* get the serial port status */

  if ( argv[2][0] == '1' )      /* set the DTR line */
    status &= ~TIOCM_DTR;
  else
    status |= TIOCM_DTR;

  if ( argv[3][0] == '1' )      /* set the RTS line */
    status &= ~TIOCM_RTS;
  else
    status |= TIOCM_RTS;

  ioctl(fd, TIOCMSET, &status); /* set the serial port status */

  close(fd);                    /* close the device file */

  return EXIT_SUCCESS;
}
