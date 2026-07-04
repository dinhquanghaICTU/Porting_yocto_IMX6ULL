
#include <common.h>
#include <command.h>
#include <asm/arch/imx-regs.h>
#include <linux/delay.h>
#include <watchdog.h>
#include <asm/io.h>
#include <console.h>


//define ra thanh ghi SNVS_HPSR vì nút nguồn là 1 gpio đặc biệt  
#define SNVS_HPSR		(SNVS_BASE_ADDR + 0x14)
#define SNVS_HPSR_BTN		BIT(6)


static int do_waitpwrkey(struct cmd_tbl *cmdtp, int flag,
			 int argc, char *const argv[])
{
	ulong hold_ms = 5000; 
	ulong start = 0;
	bool pressing = false;

	if (argc > 2)
		return CMD_RET_USAGE;

	if (argc == 2)
		hold_ms = dectoul(argv[1], NULL);

	printf("Hold ONOFF button for %lu ms to boot Linux\n", hold_ms);


    // nó gặp loop cứ hold trong này đến khi nào có evt từ nút nhấn nó mới nhảy ra thao tác tiếp 
	while (1) {
		bool pressed;

		pressed = !!(readl((void *)SNVS_HPSR) & SNVS_HPSR_BTN);
		printf("check log passed:%d\n",pressed);

		if (pressed) {
			if (!pressing) {
				start = get_timer(0);
				pressing = true;
				puts("ONOFF pressed...\n");
			}

			if (get_timer(start) >= hold_ms) {
				puts("ONOFF accepted, booting Linux...\n");
				return CMD_RET_SUCCESS;
			}
		} else {
			if (pressing)
				puts("Released too early, try again\n");

			pressing = false;
		}

		// return CMD_RET_FAILURE;

		WATCHDOG_RESET();

		if (ctrlc()) {
			puts("Boot cancelled\n");
			return CMD_RET_FAILURE;
		}

		mdelay(20);
	}
}

U_BOOT_CMD(
	waitpwrkey,
	2,
	0,
	do_waitpwrkey,
	"wait for ONOFF long press before booting Linux",
	"[hold_ms]\n"
	"    - require ONOFF to be held continuously"
);