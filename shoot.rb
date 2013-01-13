#!/usr/bin/env ruby

require 'rubygems'
require 'inline'

class Camera
  def initialize(tty)
    @tty = tty
    self.open
  end

  inline do |builder|
    builder.include '<errno.h>'
    builder.include '<fcntl.h>'
    builder.include '<unistd.h>'
    builder.include '<termios.h>'
    builder.include '<sys/ioctl.h>'
    builder.include '<ruby/dl.h>' # For the INT2BOOL macro

    builder.add_compile_flags '-std=c99', '-g'

    builder.c <<-C, :method_name => :open
      int camera_open() {
        VALUE tty = rb_iv_get(self, "@tty");
        char *path = StringValuePtr(tty);
        int fd = rb_iv_get(self, "@fd");

        struct termios tio;

        if (fd != Qnil) {
          rb_raise(rb_eArgError, "Camera is already open (fd %d)", FIX2INT(fd));
          return Qnil;
        }

        fd = open(path, O_ASYNC | O_RDWR | O_NOCTTY | O_NDELAY);

        if (fd < 0) {
          rb_raise(rb_eArgError, "Cannot open %s: %s", path, strerror(errno));
          return Qnil;
        }

        tcgetattr(fd, &tio);

        // Clear the HUPCL bit to not make the Linux kernel drop the DTR
        // when the port is closed. We don't want to stop exposure if the
        // program quits abruptly.
        //
        tio.c_cflag &= ~HUPCL;

        // Clear the CBAUD bit to not make the kernel assert the DTR and
        // RTS lines when the serial port is opened. As the camera uses
        // the RTS signal to control the shutter, just opening the serial
        // port would cause it to close if this is not set.
        //
        tio.c_cflag &= ~CBAUD;

        tcsetattr(fd, TCSANOW, &tio);

        rb_iv_set(self, "@fd", INT2FIX(fd));

        return fd;
      }
    C

    builder.c <<-C, :method_name => :close
      void camera_close() {
        int fd = FIX2INT(rb_iv_get(self, "@fd"));

        if (fd >= 0)
          close(fd);

        rb_iv_set(self, "@fd", Qnil);
      }
    C

    # Internal functions
    #
    builder.prefix <<-C
      static VALUE _camera_get_flag(VALUE self, int flag) {
        int fd, status;

        fd = FIX2INT(rb_iv_get(self, "@fd"));
        ioctl(fd, TIOCMGET, &status);

        return INT2BOOL(status & flag);
      }

      static VALUE _camera_set_flag(int argc, VALUE *argv, VALUE self, int flag) {
        int fd, status = 0;

        if (argc != 1) {
          rb_raise(rb_eArgError, "Wrong number of arguments (%d for 1)", argc);
          return Qnil;
        }

        if (argv[0] == Qtrue)
          status |= flag;
        else
          status &= ~flag;

        fd = FIX2INT(rb_iv_get(self, "@fd"));
        ioctl(fd, TIOCMSET, &status);

        return argv[0];
      }
    C

    builder.c <<-C, :method_name => :rts
      VALUE camera_get_rts() {
        return _camera_get_flag(self, TIOCM_RTS);
      }
    C

    builder.c_raw <<-C, :method_name => :rts=
      VALUE camera_set_rts(int argc, VALUE *argv, VALUE self) {
        return _camera_set_flag(argc, argv, self, TIOCM_RTS);
      }
    C

    builder.c <<-C, :method_name => :dtr
      VALUE camera_get_dtr() {
        return _camera_get_flag(self, TIOCM_DTR);
      }
    C

    builder.c_raw <<-C, :method_name => :dtr=
      VALUE camera_set_dtr(int argc, VALUE *argv, VALUE self) {
        return _camera_set_flag(argc, argv, self, TIOCM_DTR);
      }
    C

  end
end
