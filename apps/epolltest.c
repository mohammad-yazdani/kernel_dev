#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>

#if __FreeBSD__
#include <sys/event.h>
#else
#include <sys/epoll.h>
#endif

#define SELF_CLIENT 1
#define USE_TCP 1
#define SET_NB 1
#define DUP_FD 0

int main() {

#if USE_TCP
	int sfd = socket( AF_INET, SOCK_STREAM, 0 );
#else
	int sfd = socket( AF_INET, SOCK_DGRAM, 0 );
#endif

	struct sockaddr_in addr;
	memset( &addr.sin_zero, 0, sizeof(addr.sin_zero) );
  addr.sin_family = AF_INET;
  addr.sin_port = htons(0);
  addr.sin_addr.s_addr = INADDR_ANY;
	bind( sfd, (struct sockaddr*)&addr, sizeof(addr) );
  socklen_t addrlen = sizeof(addr);
	getsockname( sfd, (struct sockaddr*)&addr, &addrlen );
	printf("port: %d\n", ntohs(addr.sin_port));
#if USE_TCP
	listen( sfd, 10 );
#endif

#if SELF_CLIENT
#if USE_TCP
	listen( sfd, 10 );
	int wfd = socket( AF_INET, SOCK_STREAM, 0 );
	socklen_t on = 1;
	setsockopt( wfd, IPPROTO_TCP, TCP_NODELAY, (const void*)&on, sizeof(socklen_t));
#else
	int wfd = socket( AF_INET, SOCK_DGRAM, 0 );
#endif
	connect( wfd, (struct sockaddr*)&addr, sizeof(addr) );
#endif

#if USE_TCP
	int rfd = accept( sfd, (struct sockaddr*)&addr, &addrlen );
#else
	int rfd = sfd;
#endif

#if SET_NB
	int flags = fcntl( rfd, F_GETFL, 0 );
	fcntl( rfd, F_SETFL, flags | O_NONBLOCK );
#endif

#if __FreeBSD__
	int epfd = kqueue();
	struct kevent ev[2];
	EV_SET(&ev[0], rfd, EVFILT_READ, EV_ADD | EV_CLEAR, 0, 0, 0);
	EV_SET(&ev[1], rfd, EVFILT_WRITE, EV_ADD | EV_CLEAR, 0, 0, 0);
	kevent(epfd, ev, 2, 0, 0, 0);
#else
	int epfd = epoll_create(1);
	struct epoll_event ev = {.events = EPOLLIN | EPOLLET, .data.fd = rfd};
	epoll_ctl(epfd, EPOLL_CTL_ADD, rfd, &ev);
#endif

#if DUP_FD
	int rfd2 = dup(rfd);
#if __FreeBSD__
	EV_SET(&ev[0], rfd2, EVFILT_READ, EV_ADD | EV_CLEAR, 0, 0, 0);
	EV_SET(&ev[1], rfd2, EVFILT_WRITE, EV_ADD | EV_CLEAR, 0, 0, 0);
	kevent(epfd, ev, 2, 0, 0, 0);
#else
	ev.events = EPOLLIN | EPOLLET;
	ev.data.fd = rfd2;
	epoll_ctl(epfd, EPOLL_CTL_ADD, rfd2, &ev);
#endif
#endif

	char buf[512] = {0};

	for (int x = 0; x < 100; x += 1) {

#if SELF_CLIENT
		write(wfd, buf, 2);
#if __FreeBSD__
		static const struct timespec ts = { 0, 1000 };
		int r = kevent(epfd, 0, 0, ev, 1, &ts);
#else
		int r = epoll_wait(epfd, &ev, 1, 0);
#endif
#else
#if __FreeBSD__
		int r = kevent(epfd, 0, 0, ev, 1, 0);
#else
		int r = epoll_wait(epfd, &ev, 1, -1);
#endif
#endif

//		if (r <= 0) break;

#if __FreeBSD__
		printf("%d - kevent() got event %hd on fd %lu - ", x, ev[0].filter, ev[0].ident);
		r = read(ev[0].ident, buf, 1);
#else
		printf("%d - epoll_wait() got event %hd on fd %d - ",x, ev.events, ev.data.fd);
		r = read(ev.data.fd, buf, 1);
#endif
		printf("read %i bytes\n", r);
	}

	for (;;) {
		int r = read(ev.data.fd, buf, 512);
		if (r < 0) break;
		printf("read %i bytes at the end\n", r);
	}

	return 0;
}
