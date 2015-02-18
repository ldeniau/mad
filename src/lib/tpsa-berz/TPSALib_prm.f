!     PARAMETERS:
!
!     LDA: MAXIMUM NUMBER OF DA-VECTORS;    CAN BE CHANGED QUITE ARBITRARILY
!     LST: LENGTH OF MAIN STORAGE STACK;    CAN BE CHANGED QUITE ARBITRARILY
!     LEA: MAXIMUM NUMBER OF MONOMIALS;     CAN BE INCREASED FOR LARGE NO, NV
!     LIA: DIMENSION OF IA1, IA2;           CAN BE INCREASED FOR LARGE NO, NV
!     LNO: MAXIMUM ORDER;                   CAN BE INCREASED TO ABOUT 1000
!     LNV: MAXIMUM NUMBER OF VARIABLES;     CAN BE INCREASED TO ABOUT 1000
!
!-----------------------------------------------------------------------------1

      integer           lda, lea, lia, lno, lnv, lst

!      parameter (lda=30000, lst=132000000, lea=500000, lia=80000,       &
!      parameter (lda=30000, lst=100000000, lea=500000, lia=80000,       &
!     Tracy-3.0, Cygwin
      parameter (lda=30000, lst=80000000, lea=500000, lia=80000,        &
!     RHIC
!      parameter (lda=50000, lst=130000000, lea=500000, lia=50000,       &
!      parameter (lda=60000, lst=130000000, lea=800000, lia=80000,       &
     &           lno=15, lnv=8)

      integer           nda, ndamaxi
      common /fordes/   nda, ndamaxi

      double precision  cc, eps, epsmac
      common /da/       cc(lst), eps, epsmac

      integer           i1, i2, ie1, ie2, ieo
      integer           ia1, ia2, ifi, idano
      integer           idanv, idapo, idalm, idall
      integer           nst, nomax, nvmax, nmmax, nocut, lfi
      common /dai/      i1(lst), i2(lst), ie1(lea), ie2(lea), ieo(lea), &
     &                  ia1(0:lia), ia2(0:lia), ifi(lea), idano(lda),   &
     &                  idanv(lda), idapo(lda), idalm(lda), idall(lda), &
     &                  nst, nomax, nvmax, nmmax, nocut, lfi

      double precision  facint
      common /factor/   facint(0:lno)
!-----------------------------------------------------------------------------9
