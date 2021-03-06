SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Gestion de l'autorisation des Inits AGV
-- =============================================
CREATE PROCEDURE [dbo].[SPC_AGV_INIT]
	 @v_iag_idagv tinyint,
	 @v_iag_charge bit,
	 @v_msg_refus int out
AS
BEGIN
-- Déclaration des constantes
DECLARE @CODE_OK TINYINT,
		@CODE_KO_SPECIFIQUE TINYINT
DECLARE @TYPE_GFS TINYINT,
		@TYPE_GBH TINYINT	
DECLARE @AGV_CHARGE TINYINT
DECLARE @CODEERR_INITCHARGE_INTERDITE SMALLINT,
		@CODEERR_INITINCENDIE_INTERDITE SMALLINT,
		@CODERR_INITNONAUTORISEE SMALLINT -- (GMA0510-01)
DECLARE @VAR_INCENDIE INT
Declare @GFSInit_ChargeGFS1 Int,
		@GFSInit_ChargeGFS2	Int,
		@GFSInit_Maint		Int,
		@GFSInit_Dec1		Int,
		@GFSInit_Dec2		Int,
		@GFSInit_Dec3		Int,
		@GFSInit_DEMAC		Int,
		@GFSInit_ZA1		Int,
		@GFSInit_ZA2		Int,
		@GFSInit_ZA3		Int
-- Déclaration des variables
DECLARE @Retour INT,
		@TypeAGV TINYINT,
		@Accostage INT, -- (GMA0510-01)
		@ChaineTrace VARCHAR(200) -- (GMA0510-01)

-- Initialisation des constantes
SET @CODE_OK			= 0
SET @CODE_KO_SPECIFIQUE	= 20

SET @AGV_CHARGE = 1

SET @VAR_INCENDIE = 1025

SET @CODEERR_INITCHARGE_INTERDITE = -1147
SET @CODEERR_INITINCENDIE_INTERDITE = -1671
SET @CODERR_INITNONAUTORISEE = -2946 -- Base NON Autorisée en Initialisation


---!!!ATTENTION, IL FAUT REVOIR TOUTES CES VALEURS!!!
Set @GFSInit_ChargeGFS1 = 745
Set @GFSInit_ChargeGFS1	= 748
Set @GFSInit_Maint		= 12160
Set @GFSInit_Dec1		= 23688
Set @GFSInit_Dec2		= 23670
Set @GFSInit_Dec3		= 23666
Set @GFSInit_DEMAC		= 33145
Set @GFSInit_ZA1		= 23676
Set @GFSInit_ZA2		= 23680
Set @GFSInit_ZA3		= 23684

-- Initialisation des variables
SET @Retour = @CODE_OK

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Init Refusée avec une bobine
	IF @v_iag_charge = @AGV_CHARGE
	BEGIN
		SET @v_msg_refus = @CODEERR_INITCHARGE_INTERDITE
		SET @Retour = @CODE_KO_SPECIFIQUE
	END
	-- Init Refusée si Alarme INCENDIE ACtive
	IF EXISTS (SELECT 1 FROM PARAMETRE WHERE PAR_NOM='SPC_INCENDIE' AND PAR_VAL IN ('1','2'))
	BEGIN
		SET @v_msg_refus = @CODEERR_INITINCENDIE_INTERDITE
		SET @Retour = @CODE_KO_SPECIFIQUE
	END
	-- Init Refusée si on ne se trouve pas sur une base d'initialisation spécifique
	-- => A cause des magnets, on ne peut pas permettre les init comme on veut
	IF @Accostage NOT IN (@GFSInit_Dec1, @GFSInit_Dec2, @GFSInit_Dec3, 
							@GFSInit_ZA1, @GFSInit_ZA2, @GFSInit_ZA3, 
							@GFSInit_ChargeGFS1, @GFSInit_ChargeGFS2, @GFSInit_Maint,
							@GFSInit_DEMAC) -- Dec1Init, Dec2Init, Dec3Init, ZA1Init, ZA2Init, ZA3Init, CHGFS1, CHGFS2, MaintInit
	BEGIN
		SET @v_msg_refus = @CODERR_INITNONAUTORISEE
		SET @Retour = @CODE_KO_SPECIFIQUE
	END

RETURN @Retour

END

