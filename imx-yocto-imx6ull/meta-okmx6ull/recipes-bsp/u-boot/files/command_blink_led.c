#include <common.h>
#include <command.h>
#include <asm/gpio.h>
#include <linux/delay.h>
#include <watchdog.h>

#define LED_GPIO IMX_GPIO_NR(1, 9)

/* Ví dụ LED active-low */
#define LED_ON   0
#define LED_OFF  1

static int do_ledblink(struct cmd_tbl *cmdtp, int flag,
		       int argc, char *const argv[])
{
	unsigned int count = 5;
	unsigned int delay_ms = 500;
	unsigned int i;
	int ret;

	if (argc > 3)
		return CMD_RET_USAGE;

	if (argc >= 2)
   	/* Chuyển chuỗi thập phân sang unsigned long */
		count = dectoul(argv[1], NULL);

	if (argc >= 3)
		delay_ms = dectoul(argv[2], NULL);

	ret = gpio_request(LED_GPIO, "status-led");
	if (ret) {
		printf("Cannot request GPIO %d: %d\n", LED_GPIO, ret);
		return CMD_RET_FAILURE;
	}

	ret = gpio_direction_output(LED_GPIO, LED_OFF);
	if (ret) {
		printf("Cannot configure GPIO %d\n", LED_GPIO);
		gpio_free(LED_GPIO);
		return CMD_RET_FAILURE;
	}

	for (i = 0; i < count; i++) {
		gpio_set_value(LED_GPIO, LED_ON);
		mdelay(delay_ms);

		gpio_set_value(LED_GPIO, LED_OFF);
		mdelay(delay_ms);

		WATCHDOG_RESET();

		if (ctrlc()) {
			puts("LED blinking interrupted\n");
			break;
		}
	}

	gpio_set_value(LED_GPIO, LED_OFF);
	gpio_free(LED_GPIO);

	return CMD_RET_SUCCESS;
}

U_BOOT_CMD(
	ledblink, // định danh name of macro
	3, // tổng số tối đa agruments được truyền vào 
	0, // không repeat
	do_ledblink,// function pointer handler logic
	
	// khi gõ help ledblink =>| thì nó  xem ra giới thiệu cú pháp  
	"blink board status LED",
	"[count] [delay_ms]\n"
	"    - blink LED count times with delay in milliseconds"
);