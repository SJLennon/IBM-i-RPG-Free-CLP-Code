             PGM
             SBMJOB     CMD(CALL PGM(T9ALLOC1)) JOB(CUSTLST) +
                          JOBQ(QUSRNOMAX)
             SBMJOB     CMD(CALL PGM(T9ALLOC1)) JOB(INV_UPD) +
                          JOBQ(QUSRNOMAX)
             SBMJOB     CMD(CALL PGM(T9ALLOC1)) JOB(DAILYORD) +
                          JOBQ(QUSRNOMAX)
             SBMJOB     CMD(CALL PGM(T9ALLOC1)) JOB(YTD_RPT) +
                          JOBQ(QUSRNOMAX)
             ENDPGM
