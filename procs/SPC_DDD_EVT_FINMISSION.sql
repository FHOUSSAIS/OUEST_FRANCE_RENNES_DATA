SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Modification IdDemande int / varchar(20) (patch05)
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DDD_EVT_FINMISSION] 
	@v_numeroMessage   int, 
	@v_typeMessage     int,
	@v_horodateMessage datetime,
	@v_abonneInterne   int,
	@v_abonneExterne   int,
	@v_mission         int,
	@v_demande         varchar(20),
	@v_cause           tinyint,
	@v_agv             tinyint,
	@v_charge          int
AS
BEGIN
-- Déclaration des constantes
DECLARE @TRC_ANNULATIONMIS TINYINT
DECLARE @CODE_OK INT
DECLARE @VAR_CRDAPPELAGV    INT,
		@VAR_CAUSEANOMALIE  INT,
		@DSC_CRD_ANNULMIS	INT,
		@CRD_DMDEVACANNULEE INT
DECLARE @ADRSYS_HORS_SYSTEME BIGINT,
		@ADRBASE_HORS_SYSTEME BIGINT,
		@ADRSOUSBASE_HORS_SYSTEME BIGINT	
DECLARE @CAUSEFINMIS_ANNULATION TINYINT,
		@IDAPPEL_AGV		 INT	
Declare @ADRSYS_SRT_DEMAC BigInt,
		@ADRBASE_SRT_DEMAC BigInt,
		@ADRSOUSBASE_SRT_DEMAC BigInt

-- Déclaration des variables
DECLARE @Retour INT
DECLARE @ChaineTrace VARCHAR(200)
DECLARE @ProcStock VARCHAR(30)
DECLARE @IdBobine INT

-- Initialisation des constantes
SET @CAUSEFINMIS_ANNULATION = 9

DECLARE @ETAT_DMD_NOUVELLE		INT = 0
DECLARE @ETAT_DMD_EN_ATTENTE	INT = 1
DECLARE @ETAT_DMD_EN_COURS		INT = 2
DECLARE @ETAT_DMD_TERMINEE		INT = 3
DECLARE @ETAT_DMD_SUSPENDUE		INT = 11
DECLARE @ETAT_DMD_ANNULEE		INT = 12

SET @CODE_OK = 0

-- Initialisation des variables
SET @Retour = @CODE_OK
SET @ProcStock = 'SPC_DDD_EVT_FINMISSION'
SET @IdBobine = -1

if exists( select 1 from SPC_DMD_APPRO_DEMAC where SDD_IDDEMANDE = @v_demande )
begin
	set @ChaineTrace = 'FIN MISSION @v_mission = ' + CONVERT( varchar, ISNULL( @v_mission, -1 ) ) +
			',@v_cause=' + CONVERT(varchar,ISNULL( @v_cause, -1 ))
	exec INT_ADDTRACESPECIFIQUE @ProcStock, '[DBGMIS]', @ChaineTrace

	-- Gestion d'une annulation de mission
	IF @v_cause = @CAUSEFINMIS_ANNULATION
	BEGIN
			EXEC SPC_DDD_MODIFIER_DEMANDE @v_idDemande = @v_demande,
										@v_etat = @ETAT_DMD_ANNULEE
	END	

END
RETURN @Retour
END

