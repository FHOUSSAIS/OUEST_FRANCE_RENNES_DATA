SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Fonction		: DBG_TRACEATTRIBUTION
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: 
-- Descriptif		: Consultation des traces attribution
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[DBG_TRACEATTRIBUTION] ()
	RETURNS TABLE
AS

	RETURN (SELECT TAT_ID, TAT_DATE, ISNULL(LIB_LIBELLE, '') TAT_LIBELLE
		FROM TRACE_ATTRIBUTION (NOLOCK), TYPE_TRACE (NOLOCK), LIBELLE (NOLOCK) WHERE TAT_TYPETRC = TTC_TYPE AND LIB_TRADUCTION = TTC_IDTRADUCTION
		AND LIB_LANGUE = (SELECT PAR_VAL FROM PARAMETRE (NOLOCK) WHERE PAR_NOM = 'LANGUE'))


SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Fonction		: DBG_TRACECHARGE
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: 
-- Descriptif		: Consultation des traces charge
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[DBG_TRACECHARGE] ()
	RETURNS TABLE
AS

	RETURN (SELECT TRC_ID, TRC_DATE, ISNULL(LIB_LIBELLE, '') TRC_LIBELLE, TRC_IDCHARGE, TRC_ADRSYS, TRC_ADRBASE, TRC_ADRSSBASE, TRC_IDCLIENT,
		TRC_ORIENTATION, TRC_POSX, TRC_POSY, TRC_POSZ, TRC_POIDS, TRC_HAUTEUR, TRC_LARGEUR, TRC_LONGUEUR, TRC_PRODUIT,
		TRC_GABARIT, TRC_EMBALLAGE, TRC_COUCHE, TRC_RANG, TRC_FACE
		FROM TRACE_CHARGE (NOLOCK), TYPE_TRACE (NOLOCK), LIBELLE (NOLOCK) WHERE TRC_TYPETRC = TTC_TYPE AND LIB_TRADUCTION = TTC_IDTRADUCTION
		AND LIB_LANGUE = (SELECT PAR_VAL FROM PARAMETRE (NOLOCK) WHERE PAR_NOM = 'LANGUE'))



SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Fonction		: DBG_TRACEDEFAUT
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: 
-- Descriptif		: Consultation des traces défaut
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[DBG_TRACEDEFAUT] ()
	RETURNS TABLE
AS

	RETURN (SELECT TRD_ID, TRD_DATE, ISNULL(LIB_LIBELLE, '') TRD_LIBELLE, TRD_INFO_AGV,
		CASE TRD_TYPE WHEN 0 THEN (SELECT LIB_LIBELLE FROM DEFAUT_SPV (NOLOCK), LIBELLE (NOLOCK) WHERE DSP_ID = TRD_DEFAUT AND LIB_TRADUCTION = DSP_IDTRADUCTIONLIBELLE AND LIB_LANGUE = (SELECT PAR_VAL FROM PARAMETRE (NOLOCK) WHERE PAR_NOM = 'LANGUE'))
		ELSE (SELECT LIB_LIBELLE FROM DEFAUT_AGV (NOLOCK), INFO_AGV (NOLOCK), LIBELLE (NOLOCK) WHERE DAG_ID = TRD_DEFAUT AND IAG_ID = TRD_INFO_AGV AND LIB_TRADUCTION = DAG_IDTRADUCTIONLIBELLE
		AND LIB_LANGUE = (SELECT PAR_VAL FROM PARAMETRE (NOLOCK) WHERE PAR_NOM = 'LANGUE')) END TRD_DEFAUT
		FROM TRACE_DEFAUT (NOLOCK), TYPE_TRACE (NOLOCK), LIBELLE (NOLOCK) WHERE TRD_TYPE_TRACE = TTC_TYPE AND LIB_TRADUCTION = TTC_IDTRADUCTION
		AND LIB_LANGUE = (SELECT PAR_VAL FROM PARAMETRE (NOLOCK) WHERE PAR_NOM = 'LANGUE'))


SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Fonction		: DBG_TRACEENTREESORTIE
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: 
-- Descriptif		: Consultation des traces entrée sortie
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[DBG_TRACEENTREESORTIE] ()
	RETURNS TABLE
AS

	RETURN (SELECT TRE_ID, TRE_DATE, TRE_ENTREE_SORTIE, TRE_ETAT FROM TRACE_ENTREE_SORTIE (NOLOCK))


SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Fonction		: DBG_TRACEEXPLOITATION
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: 
-- Descriptif		: Consultation des traces exploitation
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[DBG_TRACEEXPLOITATION] ()
	RETURNS TABLE
AS

	RETURN (SELECT TEX_ID, TEX_DATE, ISNULL(LIB_LIBELLE, '') TEX_LIBELLE, TEX_IDMODE, TEX_IDAGV
		FROM TRACE_EXPLOITATION (NOLOCK), TYPE_TRACE (NOLOCK), LIBELLE (NOLOCK) WHERE TEX_TYPETRC = TTC_TYPE AND LIB_TRADUCTION = TTC_IDTRADUCTION
		AND LIB_LANGUE = (SELECT PAR_VAL FROM PARAMETRE (NOLOCK) WHERE PAR_NOM = 'LANGUE'))


SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Fonction		: DBG_TRACEMISSION
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: 
-- Descriptif		: Consultation des traces mission
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[DBG_TRACEMISSION] ()
	RETURNS TABLE
AS

	RETURN (SELECT TMI_ID, TMI_DATE, LIB_LIBELLE TMI_LIBELLE, ISNULL(dbo.SPV_DECODEVALEURMISSION(TMI_DSCTRC, TMI_TYPETRC), '') TMI_DETAIL,
		TMI_IDMISSION, TMI_IDDEMANDE, TMI_PRIORITE, TMI_DATEECHEANCE, TMI_IDCHARGE, TMI_ADRSYS, TMI_ADRBASE, TMI_ADRSSBASE, TMI_IDAGV,
		TMI_AFFINAGEADRSYS, TMI_AFFINAGEADRBASE, TMI_AFFINAGEADRSSBASE, TMI_IDTACHE, TMI_OFSPROFONDEUR TMI_OFFSETPROFONDEUR, TMI_OFSNIVEAU TMI_OFFSETNIVEAU, TMI_OFSCOLONNE TMI_OFFSETCOLONNE
		FROM TRACE_MISSION (NOLOCK), TYPE_TRACE (NOLOCK), LIBELLE (NOLOCK) WHERE TMI_TYPETRC = TTC_TYPE AND LIB_TRADUCTION = TTC_IDTRADUCTION
		AND LIB_LANGUE = (SELECT PAR_VAL FROM PARAMETRE (NOLOCK) WHERE PAR_NOM = 'LANGUE'))


SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Fonction		: DBG_TRACEORDREAGV
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: 
-- Descriptif		: Consultation des traces ordre AGV
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[DBG_TRACEORDREAGV] ()
	RETURNS TABLE
AS

	RETURN (SELECT TRO_ID, TRO_DATE, LIB_LIBELLE TRO_LIBELLE, ISNULL(dbo.SPV_DECODEVALEURORDREAGV(TRO_DSCTRC, TRO_TYPETRC), '') TRO_DETAIL, TRO_IDORDRE, TRO_IDAGV,
		TRO_ADRSYS, TRO_ADRBASE, (SELECT LIB_LIBELLE FROM ACTION (NOLOCK), LIBELLE (NOLOCK) WHERE ACT_IDACTION = TRO_ACTPRIMAIRE AND LIB_TRADUCTION = ACT_IDTRADUCTION
		AND LIB_LANGUE = (SELECT PAR_VAL FROM PARAMETRE (NOLOCK) WHERE PAR_NOM = 'LANGUE')) TRO_ACTPRIMAIRE, TRO_ACTSECONDAIRE
		FROM TRACE_ORDRE_AGV (NOLOCK), TYPE_TRACE (NOLOCK), LIBELLE (NOLOCK) WHERE TRO_TYPETRC = TTC_TYPE AND LIB_TRADUCTION = TTC_IDTRADUCTION
		AND LIB_LANGUE = (SELECT PAR_VAL FROM PARAMETRE (NOLOCK) WHERE PAR_NOM = 'LANGUE'))


SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Fonction		: DBG_TRACESPECIFIQUE
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: 
-- Descriptif		: Consultation des traces spécifiques
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[DBG_TRACESPECIFIQUE] ()
	RETURNS TABLE
AS

	RETURN (SELECT TRS_ID, TRS_DATE, TRS_MONITEUR, TRS_LOG, TRS_TRACE FROM TRACE_SPECIFIQUE (NOLOCK))

SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Fonction		: DBG_TRACEVARIABLEAUTOMATE
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: 
-- Descriptif		: Consultation des traces variable automate
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[DBG_TRACEVARIABLEAUTOMATE] ()
	RETURNS TABLE
AS

	RETURN (SELECT TRV_ID, TRV_DATE, TRV_VARIABLE_AUTOMATE, TRV_VALEUR FROM TRACE_VARIABLE_AUTOMATE (NOLOCK))


SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Fonction		: DBG_TRACEZONE
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: 
-- Descriptif		: Consultation des traces zone
-----------------------------------------------------------------------------------------
-- Révisions	
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[DBG_TRACEZONE] ()
	RETURNS TABLE
AS

	RETURN (SELECT TRZ_ID, TRZ_DATE, ISNULL(LIB_LIBELLE, '') TRZ_LIBELLE, TRZ_DSCTRC, TRZ_IDZONE
		FROM TRACE_ZONE (NOLOCK), TYPE_TRACE (NOLOCK), LIBELLE (NOLOCK) WHERE TRZ_TYPETRC = TTC_TYPE  AND LIB_TRADUCTION = TTC_IDTRADUCTION
		AND LIB_LANGUE = (SELECT PAR_VAL FROM PARAMETRE (NOLOCK) WHERE PAR_NOM = 'LANGUE'))


SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE FUNCTION [dbo].[INT_GETCAPACITE](@v_adr_idsysteme bigint, @v_adr_idbase bigint, @v_adr_idsousbase bigint,
	@v_tag_idtypeagv tinyint, @v_accesbase bit, @v_hauteur smallint, @v_largeur smallint, @v_longueur smallint, @v_face bit, @v_position tinyint)
	RETURNS smallint
AS
BEGIN

-- Déclaration des variables
DECLARE
	@v_capacite smallint

	SET @v_capacite = 0
	SET @v_longueur = CASE @v_face WHEN 0 THEN @v_longueur ELSE @v_largeur END
	SELECT @v_capacite = dbo.SPV_GETCHARGEADRESSE(@v_adr_idsysteme, @v_adr_idbase, @v_adr_idsousbase, @v_tag_idtypeagv, @v_accesbase, NULL,
		@v_hauteur, @v_largeur, @v_longueur, @v_position, 0)
	RETURN @v_capacite

END


SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE FUNCTION [dbo].[INT_GETCHARGE](@v_adr_idsysteme bigint, @v_adr_idbase bigint, @v_adr_idsousbase bigint,
	@v_accesbase bit)
	RETURNS int
AS
BEGIN
	
-- Déclaration des variables
DECLARE
	@v_chg_idcharge int,
	@v_bas_type_magasin tinyint,
	@v_bas_accumulation bit

-- Déclaration des constantes de types de magasins
DECLARE
	@TYPE_INTERFACE tinyint,
	@TYPE_STOCK tinyint,
	@TYPE_PREPARATION tinyint

-- Définition des constantes
	SET @TYPE_INTERFACE = 2
	SET @TYPE_STOCK = 3
	SET @TYPE_PREPARATION = 4

	SELECT @v_bas_type_magasin = BAS_TYPE_MAGASIN, @v_bas_accumulation = BAS_ACCUMULATION
		FROM BASE WHERE BAS_SYSTEME = @v_adr_idsysteme AND BAS_BASE = @v_adr_idbase
	IF @v_bas_type_magasin IN (@TYPE_STOCK, @TYPE_PREPARATION) AND @v_bas_accumulation = 1
		SELECT TOP 1 @v_chg_idcharge = CHG_IDCHARGE FROM INT_CHARGE_VIVANTE WHERE CHG_IDSYSTEME = @v_adr_idsysteme AND CHG_IDBASE = @v_adr_idbase
			AND CHG_IDSOUSBASE = @v_adr_idsousbase ORDER BY CASE ISNULL(@v_accesbase, 0) WHEN 0 THEN CHG_POSITIONPROFONDEUR ELSE -CHG_POSITIONPROFONDEUR END, CHG_COUCHE DESC, CHG_POSITIONNIVEAU DESC
	ELSE IF ((@v_bas_type_magasin = @TYPE_INTERFACE) OR (@v_bas_type_magasin = @TYPE_STOCK AND @v_bas_accumulation = 0))
		SELECT TOP 1 @v_chg_idcharge = CHG_IDCHARGE FROM INT_CHARGE_VIVANTE WHERE CHG_IDSYSTEME = @v_adr_idsysteme AND CHG_IDBASE = @v_adr_idbase
			AND CHG_IDSOUSBASE = @v_adr_idsousbase
	RETURN @v_chg_idcharge

END








SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE FUNCTION [dbo].[INT_GETIDBASE] (@v_tmg_idtypemagasin tinyint, @v_magasin smallint, @v_allee tinyint, @v_couloir smallint, @v_cote tinyint, @v_rack tinyint)
	RETURNS bigint
AS
BEGIN

	RETURN @v_rack + @v_cote * POWER(2, 8) + @v_couloir * POWER(2, 16)
		+ @v_allee * POWER(CONVERT(bigint, 2), 32) + @v_magasin * POWER(CONVERT(bigint, 2), 40)
		+ @v_tmg_idtypemagasin * POWER(CONVERT(bigint, 2), 56)

END






SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE FUNCTION [dbo].[INT_GETIDSOUSBASE] (@v_profondeur tinyint, @v_niveau tinyint, @v_colonne tinyint)
	RETURNS bigint
AS
BEGIN

	RETURN @v_colonne + @v_niveau * POWER(2, 8) + @v_profondeur * POWER(2, 16)

END








SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE FUNCTION [dbo].[INT_GETIDSYSTEME] (@v_cli_idclient tinyint, @v_sit_idsite tinyint, @v_sec_idsecteur tinyint)
	RETURNS bigint
AS
BEGIN

	RETURN @v_sec_idsecteur + @v_sit_idsite * POWER(2, 8) + @v_cli_idclient * POWER(2, 16)

END




SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON

CREATE FUNCTION [dbo].[INT_GETLIBELLE] (@v_tra_id int, @v_lan_id varchar(3))
	RETURNS varchar(8000)
AS
BEGIN

-- Déclaration des variables
DECLARE
	@v_lib_libelle varchar(8000),
	@v_par_valeur varchar(128)

-- Déclaration des constantes de traduction
DECLARE
	@TRAD_INCONNUE int

-- Définition des constantes
	SELECT @TRAD_INCONNUE = 788

	IF @v_tra_id IS NOT NULL
	BEGIN
		SELECT @v_par_valeur = PAR_VAL FROM PARAMETRE WHERE PAR_NOM = 'LANGUE'
		IF EXISTS (SELECT 1 FROM TRADUCTION WHERE TRA_ID = @v_tra_id)
			SELECT @v_lib_libelle = CASE WHEN ISNULL(LIB_LIBELLE, '') = '' AND @v_lan_id <> @v_par_valeur THEN dbo.INT_GETLIBELLE(@v_tra_id, @v_par_valeur)
				ELSE LIB_LIBELLE END FROM LIBELLE WHERE LIB_TRADUCTION = @v_tra_id
				AND LIB_LANGUE = CASE WHEN NOT EXISTS (SELECT 1 FROM LANGUE WHERE LAN_ID = @v_lan_id AND LAN_ACTIF = 1)
				THEN @v_par_valeur ELSE @v_lan_id END
		ELSE
			SELECT @v_lib_libelle = dbo.INT_GETLIBELLE(@TRAD_INCONNUE, @v_lan_id)
	END
	ELSE
		SELECT @v_lib_libelle = NULL
	RETURN @v_lib_libelle

END


SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE FUNCTION [dbo].[INT_GETPOSITION](@v_adr_idsysteme bigint, @v_adr_idbase bigint, @v_adr_idsousbase bigint,
	@v_tag_idtypeagv tinyint, @v_accesbase bit, @v_chg_idcharge int, @v_position tinyint)
	RETURNS @getposition TABLE (POSITIONPROFONDEUR int NULL, RANG smallint NULL, POSITIONNIVEAU int NULL, COUCHE tinyint NULL)
AS
BEGIN

-- Déclaration des variables
DECLARE
	@v_error int,
	@v_status int,
	@v_bas_type_magasin tinyint,
	@v_bas_rayonnage bit,
	@v_bas_gerbage bit,
	@v_chg_hauteur smallint,
	@v_chg_largeur smallint,
	@v_chg_longueur smallint,
	@v_chg_face bit,
	@v_chg_idgabarit tinyint,
	@v_chg_idemballage tinyint,
	@v_hauteur smallint,
	@v_longueur smallint,
	@v_offsetprofondeur int,
	@v_offsetniveau int,
	@v_offsetcolonne int,
	@v_couche tinyint,
	@v_rang smallint

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1

-- Initialisation des variables
	SET @v_error = 0
	SET @v_status = @CODE_OK

	SELECT @v_bas_type_magasin = BAS_TYPE_MAGASIN, @v_bas_rayonnage = BAS_RAYONNAGE, @v_bas_gerbage = BAS_GERBAGE FROM BASE
		WHERE BAS_SYSTEME = @v_adr_idsysteme AND BAS_BASE = @v_adr_idbase
	SELECT @v_chg_hauteur = CHG_HAUTEUR, @v_chg_largeur = CHG_LARGEUR, @v_chg_longueur = CHG_LONGUEUR, @v_chg_face = CHG_FACE,
		@v_chg_idgabarit = CHG_IDGABARIT, @v_chg_idemballage = CHG_IDEMBALLAGE
		FROM INT_CHARGE_VIVANTE WHERE CHG_IDCHARGE = @v_chg_idcharge
	-- Récupérer les dimensions de la charge du gabarit ou de l'emballage
	SELECT @v_hauteur = HAUTEUR, @v_longueur = LONGUEUR FROM dbo.SPV_DIMENSIONCHARGE(@v_chg_hauteur, @v_chg_largeur, @v_chg_longueur, @v_chg_face,
		@v_chg_idgabarit, @v_chg_idemballage)
	SELECT @v_status = RETOUR, @v_offsetprofondeur = OFFSETPROFONDEUR, @v_offsetniveau = OFFSETNIVEAU, @v_offsetcolonne = OFFSETCOLONNE	
		FROM dbo.SPV_OFFSETADRESSE(@v_tag_idtypeagv, @v_adr_idsysteme, @v_adr_idbase, @v_adr_idsousbase, NULL, @v_accesbase, @v_bas_type_magasin,
		@v_bas_rayonnage, @v_bas_gerbage, 1, @v_chg_idcharge, @v_hauteur, @v_longueur, @v_position, 0)
	SET @v_error = @@ERROR
	IF @v_status = @CODE_OK AND @v_error = 0
	BEGIN
		SELECT @v_couche = COUCHE, @v_rang = RANG
			FROM dbo.SPV_POSITIONCHARGE(@v_tag_idtypeagv, @v_adr_idsysteme, @v_adr_idbase, @v_adr_idsousbase, @v_accesbase, @v_bas_gerbage, @v_hauteur, @v_longueur, @v_position,
			@v_offsetprofondeur, @v_offsetniveau)

		INSERT INTO @getposition SELECT @v_offsetprofondeur, @v_rang, @v_offsetniveau, @v_couche
	END
	RETURN
END







SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE FUNCTION [dbo].[INT_GETSTOCKABILITE](@v_adr_idsysteme bigint, @v_adr_idbase bigint, @v_adr_idsousbase bigint,
	@v_tag_idtypeagv tinyint, @v_accesbase bit, @v_chg_idcharge int, @v_position tinyint)
	RETURNS bit
AS
BEGIN

-- Déclaration des variables
DECLARE
	@v_stockabilite bit,
	@v_chg_hauteur smallint,
	@v_chg_largeur smallint,
	@v_chg_longueur smallint,
	@v_chg_face bit,
	@v_chg_idgabarit tinyint,
	@v_chg_idemballage tinyint,
	@v_hauteur smallint,
	@v_longueur smallint

	SET @v_stockabilite = 0
	SELECT @v_chg_hauteur = CHG_HAUTEUR, @v_chg_largeur = CHG_LARGEUR, @v_chg_longueur = CHG_LONGUEUR, @v_chg_face = CHG_FACE,
		@v_chg_idgabarit = CHG_IDGABARIT, @v_chg_idemballage = CHG_IDEMBALLAGE
		FROM INT_CHARGE_VIVANTE WHERE CHG_IDCHARGE = @v_chg_idcharge
	-- Récupérer les dimensions de la charge du gabarit ou de l'emballage
	SELECT @v_hauteur = HAUTEUR, @v_longueur = LONGUEUR FROM dbo.SPV_DIMENSIONCHARGE(@v_chg_hauteur, @v_chg_largeur, @v_chg_longueur, @v_chg_face,
		@v_chg_idgabarit, @v_chg_idemballage)
	SELECT @v_stockabilite = dbo.SPV_GETCHARGEADRESSE(@v_adr_idsysteme, @v_adr_idbase, @v_adr_idsousbase, @v_tag_idtypeagv, @v_accesbase, @v_chg_idcharge,
		@v_hauteur, @v_chg_largeur, @v_longueur, @v_position, 0)
	RETURN @v_stockabilite

END







SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON

-- =============================================
-- Author:		STEPIEN Fabrice
-- Create date: 19/03/2013
-- Description:	Indique le Nombre d'AGV
--	@v_tva_idtypevariable : Type de Variable (voir Déclaration Constantes)
--  @v_var_parametre : Identifiant de la Base ou de la Zone
--  @v_idAgv  :Identifiant de l'AGV qui appelle la fonction
--	@v_agvExclu : 1 si AGV exclu du calcul
--  @v_valideTypeAgv : 1 s'il faut tenir compte unqiuement du Type AGV (utile si plusieurs type d'AGV)
-- =============================================
CREATE FUNCTION [dbo].[SPC_AGV_GETNBAGV] 
(
	@v_tva_idtypevariable int,
	@v_var_parametre varchar(3500),
	@v_idAgv int,
	@v_agvExclu int,
	@v_valideTypeAgv int = 0
)
RETURNS int
AS
BEGIN
	declare @CODE_OK int = 0
	declare @CODE_KO int = 1
	declare @ETAT_ENATTENTE int = 1
	declare @DESC_ENVOYE int = 13
	declare @TYPE_NOMBREAGVSDESTINATIONCOURANTEBASEPARAMETREE int = 1
	declare @TYPE_NOMBREAGVSDESTINATIONCOURANTEZONEPARAMETREE int = 2
	declare @TYPE_NOMBREAGVSDESTINATIONFUTUREBASEPARAMETREE int = 4
	declare @TYPE_NOMBREAGVSDESTINATIONFUTUREZONEPARAMETREE int = 5
	declare @TYPE_NOMBREAGVSORIGINEBASEPARAMETREE int = 11
	declare @TYPE_NOMBREAGVSORIGINEZONEPARAMETREE int = 12
	
	declare @v_crz_valeur int = 0,
			@typeAgv int = ( select IAG_TYPE from INFO_AGV where IAG_ID = @v_idAgv )
	
	IF @v_tva_idtypevariable = @TYPE_NOMBREAGVSDESTINATIONCOURANTEBASEPARAMETREE
	begin
		SELECT @v_crz_valeur = COUNT(*) FROM INFO_AGV 
		WHERE IAG_OPERATIONNEL = 'O' 
		AND   (    (                 IAG_BASE_DEST = @v_var_parametre
			         AND NOT EXISTS ( SELECT 1 FROM ORDRE_AGV 
								      WHERE ORD_IDAGV = IAG_ID AND ORD_IDETAT = @ETAT_ENATTENTE AND ORD_DSCETAT = @DESC_ENVOYE ) )
			    OR EXISTS ( SELECT 1 FROM ORDRE_AGV, TACHE 
							WHERE ORD_IDAGV = IAG_ID AND TAC_IDORDRE = ORD_IDORDRE
							AND ORD_IDETAT = @ETAT_ENATTENTE AND ORD_DSCETAT = @DESC_ENVOYE
							AND TAC_IDADRSYS = (SELECT TOP 1 SYS_SYSTEME FROM SYSTEME) AND TAC_IDADRBASE = @v_var_parametre ) )
		AND ( ( @v_agvExclu = 1 and IAG_ID <> @v_idAgv ) or ( @v_agvExclu = 0 ) )
		AND ( ( @v_valideTypeAgv = 1 and IAG_TYPE = @typeAgv ) or ( @v_valideTypeAgv = 0 ) )
	end
	ELSE IF @v_tva_idtypevariable = @TYPE_NOMBREAGVSDESTINATIONCOURANTEZONEPARAMETREE
	begin
		SELECT @v_crz_valeur = COUNT(*) FROM INFO_AGV WHERE IAG_OPERATIONNEL = 'O' AND ((IAG_BASE_DEST IN (SELECT CZO_ADR_KEY_BASE FROM ZONE_CONTENU WHERE CZO_ZONE = @v_var_parametre)
			AND NOT EXISTS (SELECT 1 FROM ORDRE_AGV WHERE ORD_IDAGV = IAG_ID AND ORD_IDETAT = @ETAT_ENATTENTE AND ORD_DSCETAT = @DESC_ENVOYE))
			OR EXISTS (SELECT 1 FROM ORDRE_AGV, TACHE, ZONE_CONTENU WHERE ORD_IDAGV = IAG_ID AND TAC_IDORDRE = ORD_IDORDRE AND ORD_IDETAT = @ETAT_ENATTENTE AND ORD_DSCETAT = @DESC_ENVOYE
			AND CZO_ZONE = @v_var_parametre AND TAC_IDADRSYS = CZO_ADR_KEY_SYS AND TAC_IDADRBASE = CZO_ADR_KEY_BASE))
			AND ( ( @v_agvExclu = 1 and IAG_ID <> @v_idAgv ) or ( @v_agvExclu = 0 ) )
			AND ( ( @v_valideTypeAgv = 1 and IAG_TYPE = @typeAgv ) or ( @v_valideTypeAgv = 0 ) )
	end
	ELSE IF @v_tva_idtypevariable = @TYPE_NOMBREAGVSDESTINATIONFUTUREBASEPARAMETREE
	begin
			SELECT @v_crz_valeur = COUNT(*) FROM INFO_AGV WHERE IAG_OPERATIONNEL = 'O' AND ((IAG_BASE_DEST = @v_var_parametre
				AND NOT EXISTS (SELECT 1 FROM ORDRE_AGV WHERE ORD_IDAGV = IAG_ID))
				OR EXISTS (SELECT 1 FROM ORDRE_AGV, TACHE WHERE ORD_IDAGV = IAG_ID AND TAC_IDORDRE = ORD_IDORDRE
				AND TAC_IDADRSYS = (SELECT TOP 1 SYS_SYSTEME FROM SYSTEME) AND TAC_IDADRBASE = @v_var_parametre))
				AND ( ( @v_agvExclu = 1 and IAG_ID <> @v_idAgv ) or ( @v_agvExclu = 0 )  )
				AND ( ( @v_valideTypeAgv = 1 and IAG_TYPE = @typeAgv ) or ( @v_valideTypeAgv = 0 ) )
	end	
	ELSE IF @v_tva_idtypevariable = @TYPE_NOMBREAGVSDESTINATIONFUTUREZONEPARAMETREE
	begin
			SELECT @v_crz_valeur = COUNT(*) FROM INFO_AGV WHERE IAG_OPERATIONNEL = 'O' AND ((IAG_BASE_DEST IN (SELECT CZO_ADR_KEY_BASE FROM ZONE_CONTENU WHERE CZO_ZONE = @v_var_parametre)
				AND NOT EXISTS (SELECT 1 FROM ORDRE_AGV WHERE ORD_IDAGV = IAG_ID))
				OR EXISTS (SELECT 1 FROM ORDRE_AGV, TACHE, ZONE_CONTENU WHERE ORD_IDAGV = IAG_ID AND TAC_IDORDRE = ORD_IDORDRE
				AND CZO_ZONE = @v_var_parametre AND TAC_IDADRSYS = CZO_ADR_KEY_SYS AND TAC_IDADRBASE = CZO_ADR_KEY_BASE))
				AND ( ( @v_agvExclu = 1 and IAG_ID <> @v_idAgv ) or ( @v_agvExclu = 0 )  )
				AND ( ( @v_valideTypeAgv = 1 and IAG_TYPE = @typeAgv ) or ( @v_valideTypeAgv = 0 ) )
	end
	ELSE IF @v_tva_idtypevariable = @TYPE_NOMBREAGVSORIGINEBASEPARAMETREE
	begin
			SELECT @v_crz_valeur = COUNT(*) FROM INFO_AGV WHERE IAG_OPERATIONNEL = 'O' 
			AND (      ( IAG_BASE_ORIG = @v_var_parametre )
					or exists( select 1 from INT_TACHE_MISSION
							 join INT_MISSION_VIVANTE on TAC_IDMISSION = MIS_IDMISSION
							 where TAC_IDBASEEXECUTION = @v_var_parametre and TAC_IDETATTACHE = 5
							 and MIS_IDAGV = IAG_ID ) )
				AND ( ( @v_agvExclu = 1 and IAG_ID <> @v_idAgv ) or ( @v_agvExclu = 0 ) )
				AND ( ( @v_valideTypeAgv = 1 and IAG_TYPE = @typeAgv ) or ( @v_valideTypeAgv = 0 ) )
	end
	ELSE IF @v_tva_idtypevariable = @TYPE_NOMBREAGVSORIGINEZONEPARAMETREE
	begin
			SELECT @v_crz_valeur = COUNT(*) FROM INFO_AGV 
			WHERE IAG_OPERATIONNEL = 'O' 
			AND (    ( IAG_BASE_ORIG IN (SELECT CZO_ADR_KEY_BASE FROM ZONE_CONTENU WHERE CZO_ZONE = @v_var_parametre) )
				  or exists( select 1 from INT_TACHE_MISSION
							 join INT_MISSION_VIVANTE on TAC_IDMISSION = MIS_IDMISSION
							 where TAC_IDBASEEXECUTION IN (SELECT CZO_ADR_KEY_BASE FROM ZONE_CONTENU WHERE CZO_ZONE = @v_var_parametre) and TAC_IDETATTACHE = 5
							 and MIS_IDAGV = IAG_ID ) )
			AND ( ( @v_agvExclu = 1 and IAG_ID <> @v_idAgv ) or ( @v_agvExclu = 0 ) )
			AND ( ( @v_valideTypeAgv = 1 and IAG_TYPE = @typeAgv ) or ( @v_valideTypeAgv = 0 ) )
	end
	
	return @v_crz_valeur
	
END

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON

-- =============================================
-- Description:	Gestion de l'évaluation si la charge doit être gerbée ou non
-- @v_chg_idcharge_last : identifiant de la dernière charge
-- @v_chg_idcharge_next : identifiant de la prochaine charge
-- =============================================
CREATE FUNCTION [dbo].[SPC_CHG_EVAL_GERBAGE]
(
	@v_chg_idcharge_last int,
	@v_chg_idcharge_next int
)
RETURNS BIT
AS
BEGIN
-- Déclaration des constantes
DECLARE @GERBAGE_OK BIT
DECLARE @GERBAGE_AUSOL BIT

-- Déclaration des variables
DECLARE @GerbageBobine BIT
DECLARE @LaizeBobine SMALLINT,
		@DiametreBobine SMALLINT,
		@NiveauBobineEnStock SMALLINT
DECLARE @AdrSysAlleeStockage BIGINT,
		@AdrBaseAlleeStockage BIGINT,
		@AdrSousBaseAlleeStockage BIGINT,
		@HauteurMaxAlleeStockage INT,
		@NiveauMaxAlleeStockage SMALLINT	

-- Initialisation des constantes
SET @GERBAGE_OK		= 1
SET @GERBAGE_AUSOL	= 0

-- Initialisation des variables
SET @GerbageBobine = @GERBAGE_OK

IF @v_chg_idcharge_last = 0
BEGIN
	SET @GerbageBobine = @GERBAGE_OK
END
ELSE
BEGIN
	-- Recherche du lieu de stockage, du diamètre et de la laize de la dernière bobine stockée
	SELECT @LaizeBobine = CHG_HAUTEUR, @DiametreBobine = CHG_LARGEUR,
			@AdrSysAlleeStockage = CHG_IDSYSTEME,
			@AdrBaseAlleeStockage = CHG_IDBASE,
			@AdrSousBaseAlleeStockage = CHG_IDSOUSBASE,
			@HauteurMaxAlleeStockage = STR_HAUTEUR_COURANTE,
			@NiveauBobineEnStock = CHG_POSITIONNIVEAU
		FROM INT_CHARGE_VIVANTE
	LEFT OUTER JOIN SPC_ADRESSE_STOCK_GENERAL ON CHG_IDSYSTEME = SAG_IDSYSTEME
								AND CHG_IDBASE = SAG_IDBASE
								AND CHG_IDSOUSBASE = SAG_IDSOUSBASE
	INNER JOIN STRUCTURE ON CHG_IDSYSTEME = STR_SYSTEME
								AND CHG_IDBASE = STR_BASE
								AND CHG_IDSOUSBASE = STR_SOUSBASE							
	WHERE CHG_IDCHARGE = @v_chg_idcharge_last
	
	-- Pour toutes les allées du stock de masse et stock tampon
	-- Si le client a limité le nombre de bobines en hauteur et que celui ci est atteint
	-- => Forçage du gerbage au sol
	---------------------------------------------------------------------------------
	IF @GerbageBobine <> @GERBAGE_AUSOL
	BEGIN
		SET @NiveauMaxAlleeStockage = dbo.SPC_STK_GETNIVEAUMAXALLEE (@LaizeBobine, 
													@AdrSysAlleeStockage,
													@AdrBaseAlleeStockage,
													@AdrSousBaseAlleeStockage)
		-- Si le niveau de la dernière bobine en stock correspond au niveau max autorisé dans l'allée
		IF @NiveauBobineEnStock >= (@NiveauMaxAlleeStockage - @LaizeBobine)
		BEGIN
			SET @GerbageBobine = @GERBAGE_AUSOL
		END
	END
END	

-- Retourne la valeur de gerbage calculée
RETURN @GerbageBobine

END


SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Récupère l'état de la bobine en station de déballage
-- Description:	Renvoie l'information bobine inconnue(1) ou connue(0)
-- =============================================
CREATE FUNCTION [dbo].[SPC_DMC_GETETATBOBINEDEBALLAGE]
(
	@v_idLigne INT
)
RETURNS int
AS
BEGIN
	DECLARE @val_newBobine INT
	DECLARE @simulation_demaculeuse INT = (SELECT CONVERT(INT, dbo.PARAMETRE.PAR_VAL) FROM dbo.PARAMETRE WHERE dbo.PARAMETRE.PAR_NOM = 'SPC_SIMU_DEMAC')

	SELECT
		@val_newBobine = dbo.INT_VARIABLE_AUTOMATE.VAU_VALEUR
	FROM dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE
	JOIN dbo.INT_VARIABLE_AUTOMATE ON dbo.INT_VARIABLE_AUTOMATE.VAU_IDVARIABLEAUTOMATE = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_NEWBOBINE
	WHERE dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_ACTION = 31
	AND dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDLIGNE = @v_idLigne
	AND ( dbo.INT_VARIABLE_AUTOMATE.VAU_QUALITE = 1 OR @simulation_demaculeuse = 1)
	
	RETURN ISNULL(@val_newBobine, 0)
	
END


SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Author:		G.MASSARD
-- Create date: 09/07/2010
-- Description:	Renvoie l'état du Convoyeur de DEMACULAGE ou du basculeur
-- =============================================
CREATE FUNCTION [dbo].[SPC_DMC_GETETATLIGNE]
(
	@v_IdLigne INT
)
RETURNS int
AS
BEGIN
	DECLARE @VAR_ETAT_DEMACULAGE_5 INT,
			@VAR_ETAT_DEMACULAGE_6 INT

	declare @cvy_etat int,
			@VarEtatConvoyeur int,
			@LectureEnCours Int,
			@EtatInterface Int,
			@Simulation Int
	
	SET @VAR_ETAT_DEMACULAGE_5 = 1
	SET @VAR_ETAT_DEMACULAGE_6 = 14
	
	SET @VarEtatConvoyeur = NULL
	SET @cvy_etat = NULL
	
	IF @v_IdLigne = 5
		SET @VarEtatConvoyeur = @VAR_ETAT_DEMACULAGE_5
	IF @v_IdLigne = 6
		SET @VarEtatConvoyeur = @VAR_ETAT_DEMACULAGE_6
		
	SELECT @Simulation = CONVERT(INT,PAR_VAL) FROM PARAMETRE WHERE PAR_NOM='SPC_SIMULATION'
	
	Select @cvy_etat = VAU_VALEUR, @LectureEnCours = VAU_READ, @EtatInterface = VAU_QUALITE 
		From INT_VARIABLE_AUTOMATE
			Where VAU_IDVARIABLEAUTOMATE = @VarEtatConvoyeur

	If @Simulation=1
		Set @cvy_etat = 1

	-- non prise en compte de l'info tant qu'elle n'est pas lue
	-- non prise en compte de l'info si l'interface n'est pas active
	if (@LectureEnCours = 1 or @EtatInterface = 0) And (@Simulation=0)
		Set @cvy_etat = 0
		
	return @cvy_etat
END

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Position du Skate d’entrée
-- @v_IdLigne	: Ligne de la démac
-- =============================================
CREATE FUNCTION [dbo].[SPC_DMC_GETPOSITIONSKATE]
(
	@v_IdLigne INT
)
RETURNS int
AS
BEGIN
	DECLARE @VAR_POS_DEMAC INT
			
	declare @VarPositionSkate int,	
			@LectureEnCours Int,
			@EtatInterface Int,
			@Simulation Int

	IF @v_IdLigne = 5
		SET @VAR_POS_DEMAC = 3 -- Action 12
	IF @v_IdLigne = 6
		SET @VAR_POS_DEMAC = 53 -- Action 12

	--SELECT @Simulation = CONVERT(INT,PAR_VAL) FROM PARAMETRE WHERE PAR_NOM='SPC_SIMULATION'

	Select @VarPositionSkate = VAU_VALEUR, @LectureEnCours = VAU_READ, @EtatInterface = VAU_QUALITE 
		From INT_VARIABLE_AUTOMATE
			Where VAU_IDVARIABLEAUTOMATE = @VAR_POS_DEMAC
	
	/*If @Simulation=1
		Set @VarPositionSkate = 1*/

	-- non prise en compte de l'info tant qu'elle n'est pas lue
	-- non prise en compte de l'info si l'interface n'est pas active
	if (@LectureEnCours = 1 or @EtatInterface = 0) And (@Simulation=0)
		Set @VarPositionSkate = 0

	return @VarPositionSkate
END

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Recherche de l'état d'une allée de stockage
-- @v_IdLaize : Identifiant Laize
-- @v_IdDiametre : Identifiant Diametre
-- @AdrSysAllee  : systeme de base d'execution
-- @AdrBaseAllee : systeme de base d'execution
-- @AdrSousBaseAllee  : systeme de base d'execution
-- =============================================
CREATE FUNCTION [dbo].[SPC_STK_GETETATALLEE]
(
	@IdLaize INT,
	@IdDiametre INT,
	@AdrSysAllee BIGINT,
	@AdrBaseAllee BIGINT,
	@AdrSousBaseAllee BIGINT
)
RETURNS TINYINT
AS
BEGIN
-- Déclaration des constantes
DECLARE @ALLEE_OCCUPEE INT,
		@ALLEE_PLEINE INT

-- Initialisation des constantes
SET @ALLEE_OCCUPEE  = 2
SET @ALLEE_PLEINE	= 3

-- Déclaration des variables
DECLARE @EtatAllee INT
DECLARE @NbPlacesVides INT
DECLARE @EtatAlleeSTD INT

	-- Recherche du nombre d'emplacements vides
	EXEC  @NbPlacesVides = dbo.INT_GETCAPACITE @AdrSysAllee,@AdrBaseAllee,@AdrSousBaseAllee,1,0,@IdLaize,@IdDiametre,@IdDiametre,0,0
	SELECT @EtatAlleeSTD = ADR_IDETAT_OCCUPATION from INT_ADRESSE
		WHERE ADR_IDSYSTEME = @AdrSysAllee
			AND ADR_IDBASE = @AdrBaseAllee
			AND ADR_IDSOUSBASE = @AdrSousBaseAllee

	SET @EtatAllee = @EtatAlleeSTD
	IF @EtatAllee = @ALLEE_OCCUPEE
		AND @NbPlacesVides = 0
	BEGIN
		SET @EtatAllee = @ALLEE_PLEINE
	END

	-- Return the result of the function
	RETURN @EtatAllee
END

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Calcul du niveau de dépose max autorisé dans une allée
-- @IdLaize : Identifiant de Laize
-- @AdrSysAllee  : systeme de base d'execution
-- @AdrBaseAllee : systeme de base d'execution
-- @AdrSousBaseAllee  : systeme de base d'execution
-- =============================================
CREATE FUNCTION [dbo].[SPC_STK_GETNIVEAUMAXALLEE]
(
	@IdLaize INT,
	@AdrSysAllee BIGINT,
	@AdrBaseAllee BIGINT,
	@AdrSousBaseAllee BIGINT
)
RETURNS SMALLINT
AS
BEGIN
	-- Déclaration des variables
	DECLARE @NiveauMaxAllee SMALLINT,
			@NbMaxHauteur INT,
			@HauteurLaize INT

	-- Recherche du niveau max associé à l'allée
	SELECT @NiveauMaxAllee = STRUCTURE.STR_HAUTEUR_COURANTE from STRUCTURE
		where STRUCTURE.STR_SYSTEME = @AdrSysAllee
			and STRUCTURE.STR_BASE = @AdrBaseAllee
			and STRUCTURE.STR_SOUSBASE = @AdrSousBaseAllee

	-- Retourne la valeur de gerbage calculée
	RETURN @NiveauMaxAllee
END

SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Fonction		: SPV_CONVERTINTTOVARCHAR
-- Paramètre d'entrée	: @vp_num : Entier a convertir en chaine de caractères
--			  @vp_len : taille de la chaine de caractères de retour	
-- Paramètre de sortie	: Entier convertit en chaine de caractères.
-- Descriptif		: Cette procédure convertit un entier en chaine de caractères de longeur voulue.
--			  Des 0 sont ajoutés en début de chaine pour obtenir la longueur voulue.
-----------------------------------------------------------------------------------------
-- Révisions	
-----------------------------------------------------------------------------------------
-- Date			: 28/06/2005 									
-- Auteur		: M. Crosnier
-- Libellé			: Création de la procédure						
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Standardisation Logistic Core
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[SPV_CONVERTINTTOVARCHAR] (@vp_num int,@vp_len int)
	RETURNS varchar(120)
AS
begin
--déclaration des variables
declare @v_lenNum int
declare @v_strNum varchar(120)
declare @v_string varchar(120)

set @v_strNum = CONVERT(varchar, @vp_num)
set @v_lenNum = LEN(@v_strNum)
if (@v_lenNum >= @vp_len)
begin
  -- L'entier a codé est plus grand que la longueur demandée, on retourne la chaine contenant l'entier
  set @v_string = @v_strNum
end
else begin
  -- On ajoute des 0 en début de chaine pour avoir la longueur voulue
  set @v_string = REPLICATE('0', @vp_len-@v_lenNum) + @v_strNum
end

return @v_string
end









SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Fonction		: SPV_DECODEVALEURMISSION
-- Paramètre d'entrée	: @v_value : Chaîne de caractères codée
--			  @v_objet : Objet
-- Paramètre de sortie	: @v_str : Chaîne de caractères explicite
-- Descriptif		: Cette procédure décode une chaîne de caractères codée
--			  en une description explicite.
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[SPV_DECODEVALEURMISSION] (@v_value varchar(100), @v_objet tinyint)
	RETURNS varchar(1000)
AS
begin
  -- déclaration des variables
  declare @v_idEtat tinyint
  declare @v_dscEtat tinyint
  declare @v_detailExec tinyint
  declare @v_str varchar(1000)
  declare @v_pos integer
  declare @v_crdExec bit
  declare @v_idAction integer
  declare @v_infoExec varchar(100)
  declare @v_idTache int
  DECLARE
    @v_par_valeur varchar(128)

  -- déclaration des constantes
  declare @CHANGE_ETAT tinyint
  declare @EXECUTION_TACHE tinyint
  declare @AFFINAGE_TACHE tinyint
  declare @CHANGE_PRIORITE tinyint
  declare @CHANGE_ECHEANCE tinyint
  declare @TACHE_OK tinyint

  set @CHANGE_ETAT = 2
  set @CHANGE_PRIORITE = 3
  set @CHANGE_ECHEANCE = 4
  set @EXECUTION_TACHE = 7 
  set @AFFINAGE_TACHE = 20
  set @TACHE_OK = 0
 
  SELECT @v_par_valeur = PAR_VAL FROM PARAMETRE (NOLOCK) WHERE PAR_NOM = 'LANGUE'
  -- changement d'état Mission 
  if (@v_objet = @CHANGE_ETAT)
  begin 
    set @v_pos = charindex(';',@v_value)
    if (@v_pos <> 0)
    begin
      -- Récupération de l'état de la mission
      set @v_idEtat = substring(@v_value,1,@v_pos-1)
      set @v_value = substring(@v_value,@v_pos+1,len(@v_value)-@v_pos)

      select @v_str=isNull(LIB_Libelle,'') from ETAT_MISSION (NOLOCK)
      join TRADUCTION (NOLOCK) on (ETM_IdTraduction = TRA_Id) 
      join LIBELLE (NOLOCK) on (LIB_Traduction = TRA_Id) and (LIB_Langue=@v_par_valeur)
      where ETM_IdEtat=@v_idEtat
             
      set @v_pos = charindex(';',@v_value)
      if (@v_pos <> 0)
      begin
        -- Récupération de la raison du changement d'état
        set @v_dscEtat = substring(@v_value,1,@v_pos-1)
        set @v_value = substring(@v_value,@v_pos+1,len(@v_value)-@v_pos) 
      end
      
      select @v_str=@v_str+' - '+isNull(LIB_Libelle,'') from DESC_ETAT_TACHE (NOLOCK)
      join TRADUCTION (NOLOCK) on (DET_IdTraduction = TRA_Id) 
      join LIBELLE (NOLOCK) on (LIB_Traduction = TRA_Id) and (LIB_Langue=@v_par_valeur)
      where DET_DscEtat=@v_dscEtat
    end
  end
  -- changement d'exécution tâche
  else if (@v_objet = @EXECUTION_TACHE)
  begin
    set @v_pos = charindex(';',@v_value)
    if (@v_pos <> 0)
    begin
      -- Récupération de l'action de la tâche
      set @v_idAction = substring(@v_value,1,@v_pos-1)
      set @v_value = substring(@v_value,@v_pos+1,len(@v_value)-@v_pos)

      select @v_str=isNull(LIB_Libelle,'') from ACTION (NOLOCK)
      join TRADUCTION (NOLOCK) on (ACT_IdTraduction = TRA_Id) 
      join LIBELLE (NOLOCK) on (LIB_Traduction = TRA_Id) and (LIB_Langue=@v_par_valeur)
      where ACT_IdAction=@v_idAction

      set @v_pos = charindex(';',@v_value)
      if (@v_pos <> 0)
      begin
        -- récupération du code d'exécution de la tâche
        set @v_crdExec = substring(@v_value,1,@v_pos-1)
        set @v_value = substring(@v_value,@v_pos+1,len(@v_value)-@v_pos)

        if (@v_crdExec = @TACHE_OK)
          set @v_str=@v_str+' - '+'OK'
        else
           set @v_str=@v_str+' - '+'KO'

        set @v_pos = charindex(';',@v_value)
        if (@v_pos <> 0)
        begin
          -- récupération du détail d'exécution de la tâche
          set @v_detailExec = substring(@v_value,1,@v_pos-1)
          set @v_value = substring(@v_value,@v_pos+1,len(@v_value)-@v_pos)

          select @v_str=@v_str+' - '+isNull(LIB_Libelle,'') from DESC_ETAT_TACHE (NOLOCK)
          join TRADUCTION (NOLOCK) on (DET_IdTraduction = TRA_Id) 
          join LIBELLE (NOLOCK) on (LIB_Traduction = TRA_Id) and (LIB_Langue=@v_par_valeur)
          where DET_DscEtat=@v_detailExec
   
          set @v_pos = charindex(';',@v_value)
          if (@v_pos <> 0)
          begin
            -- récupération des infos relevées lors de l'exécution de la tâche
            set @v_infoExec = substring(@v_value,1,@v_pos-1)
            set @v_value = substring(@v_value,@v_pos+1,len(@v_value)-@v_pos)

            set @v_str=@v_str+' - '+@v_infoExec
          end
        end
      end
    end 
  end
  -- affinage tâche
  else if (@v_objet = @AFFINAGE_TACHE)
  begin
	select @v_idAction = @v_value
    select @v_str=isNull(LIB_Libelle,'') from ACTION (NOLOCK)
    join TRADUCTION (NOLOCK) on (ACT_IdTraduction = TRA_Id) 
    join LIBELLE (NOLOCK) on (LIB_Traduction = TRA_Id) and (LIB_Langue=@v_par_valeur)
    where ACT_IdAction=@v_idAction
  end
  -- changement priorité mission
  else if (@v_objet = @CHANGE_PRIORITE)
  begin
    select @v_str = @v_value
  end
  -- changement échéance mission
  else if (@v_objet = @CHANGE_ECHEANCE)
  begin
    select @v_str = @v_value
  end
  -- autres changements
  else
  begin
    select @v_str=isNull(LIB_Libelle,'') from DESC_ETAT_TACHE (NOLOCK)
    join TRADUCTION (NOLOCK) on (DET_IdTraduction = TRA_Id) 
    join LIBELLE (NOLOCK) on (LIB_Traduction = TRA_Id) and (LIB_Langue=@v_par_valeur)
    where DET_DscEtat=@v_value
  end

  return (@v_str)
end











SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON




-----------------------------------------------------------------------------------------
-- Fonction		: SPV_DECODEVALEURORDREAGV
-- Paramètre d'entrée	: @v_value : Chaîne de caractères codée
--			  @v_objet : Objet
-- Paramètre de sortie	: @v_str : Chaîne de caractères explicite
-- Descriptif		: Cette procédure décode une chaîne de caractères codée
--			  en une description explicite.
-----------------------------------------------------------------------------------------
-- Révisions	
-----------------------------------------------------------------------------------------
-- Date			: 01/11/2004
-- Auteur		: S.Loiseau
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Date			: 07/06/2005									
-- Auteur		: S.Loiseau									
-- Libellé			: Modification de la fonction suite au multilangue					
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Standardisation Logistic Core
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[SPV_DECODEVALEURORDREAGV] (@v_value varchar(100),@v_objet tinyint)
	RETURNS varchar(1000)
AS
begin
  -- déclaration des variables
  declare @v_idEtat tinyint
  declare @v_dscEtat tinyint
  declare @v_detailExec tinyint
  declare @v_str varchar(1000)
  declare @v_pos integer
  declare @v_crdExec bit
  declare @v_idAction integer
  declare @v_infoExec varchar(100)
  DECLARE
    @v_par_valeur varchar(128)

  -- déclaration des constantes
  declare @CHANGE_ETAT tinyint
  declare @EXECUTION_TACHE tinyint
  declare @TACHE_OK tinyint

  set @CHANGE_ETAT = 2
  set @EXECUTION_TACHE = 7 
  set @TACHE_OK = 0
 
  SELECT @v_par_valeur = PAR_VAL FROM PARAMETRE (NOLOCK) WHERE PAR_NOM = 'LANGUE'
  -- changement d'état Mission --
  if (@v_objet = @CHANGE_ETAT)
  begin 
    set @v_pos = charindex(';',@v_value)
    if (@v_pos <> 0)
    begin
      -- Récupération de l'état de l'ordre
      set @v_idEtat = substring(@v_value,1,@v_pos-1)
      set @v_value = substring(@v_value,@v_pos+1,len(@v_value)-@v_pos)

      select @v_str=isNull(LIB_Libelle,'') from ETAT_ORDRE (NOLOCK)
      join TRADUCTION (NOLOCK) on (ETO_IdTraduction = TRA_Id) 
      join LIBELLE (NOLOCK) on (LIB_Traduction = TRA_Id) and (LIB_Langue=@v_par_valeur)
      where ETO_IdEtat=@v_idEtat
           
      set @v_pos = charindex(';',@v_value)
      if (@v_pos <> 0)
      begin
        -- Récupération de la raison du changement d'état
        set @v_dscEtat = substring(@v_value,1,@v_pos-1)
        set @v_value = substring(@v_value,@v_pos+1,len(@v_value)-@v_pos) 
      end
      
      select @v_str=@v_str+' - '+isNull(LIB_Libelle,'') from DESC_ETAT_ORDRE (NOLOCK)
      join TRADUCTION (NOLOCK) on (DEO_IdTraduction = TRA_Id) 
      join LIBELLE (NOLOCK) on (LIB_Traduction = TRA_Id) and (LIB_Langue=@v_par_valeur)
      where DEO_DscEtat=@v_dscEtat
    end
  end
  else 
  begin
    select @v_str=isNull(LIB_Libelle,'') from DESC_ETAT_ORDRE (NOLOCK)
    join TRADUCTION (NOLOCK) on (DEO_IdTraduction = TRA_Id) 
    join LIBELLE (NOLOCK) on (LIB_Traduction = TRA_Id) and (LIB_Langue=@v_par_valeur)
    where DEO_DscEtat=@v_value
  end

  return (@v_str)
end












SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procedure		: SPV_DIMENSIONCHARGE
-- Paramètre d'entrée	: @v_chg_hauteur : Hauteur
--			  @v_chg_largeur : Largeur
--			  @v_chg_longueur : Longueur
--			  @v_chg_face : Face
--			  @v_chg_idgabarit : Identifiant gabarit
--			  @v_chg_idemballage : Identifiant emballage
-- Paramètre de sortie	: @v_hauteur : Hauteur
--			  @v_longueur : Longueur
--			  Valeur de retour :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
-- Descriptif		: Calcul des dimensions d'une charge
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[SPV_DIMENSIONCHARGE](@v_chg_hauteur smallint, @v_chg_largeur smallint, @v_chg_longueur smallint,
	@v_chg_face bit, @v_chg_idgabarit tinyint, @v_chg_idemballage tinyint)
	RETURNS @dimensioncharge TABLE (HAUTEUR smallint NULL, LONGUEUR smallint NULL)
AS
BEGIN

-- Déclaration des variables
DECLARE
	@v_hauteur smallint,
	@v_longueur smallint,
	@v_gbr_hauteur smallint,
	@v_gbr_longueur smallint,
	@v_emb_hauteur smallint,
	@v_emb_longueur smallint

	SELECT @v_gbr_hauteur = GBR_HAUTEUR, @v_gbr_longueur = CASE @v_chg_face WHEN 0 THEN GBR_LONGUEUR ELSE GBR_LARGEUR END FROM GABARIT WHERE GBR_ID = @v_chg_idgabarit
	SELECT @v_emb_hauteur = EMB_HAUTEUR, @v_emb_longueur = CASE @v_chg_face WHEN 0 THEN EMB_LONGUEUR ELSE EMB_LARGEUR END FROM EMBALLAGE WHERE EMB_ID = @v_chg_idemballage
	SET @v_hauteur = ISNULL(@v_chg_hauteur, ISNULL(@v_gbr_hauteur, @v_emb_hauteur))
	SET @v_longueur = CASE @v_chg_face WHEN 0 THEN ISNULL(@v_chg_longueur, 0) ELSE ISNULL(@v_chg_largeur, 0) END
	SET @v_longueur = CASE WHEN @v_longueur > ISNULL(@v_gbr_longueur, 0) THEN @v_longueur ELSE ISNULL(@v_gbr_longueur, 0) END
	SET @v_longueur = CASE WHEN @v_longueur > ISNULL(@v_emb_longueur, 0) THEN @v_longueur ELSE ISNULL(@v_emb_longueur, 0) END
	
	INSERT INTO @dimensioncharge SELECT @v_hauteur, @v_longueur
	RETURN
END

SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF




-----------------------------------------------------------------------------------------
-- Fonction		: SPV_GETCHARGEADRESSE
-- Paramètre d'entrée	: @v_adr_idsysteme : Clé système adresse
--			  @v_adr_idbase : Clé base adresse
--			  @v_adr_idsousbase : Clé sous-base adresse
--			  @v_tag_idtypeagv : Type AGV
--			  @v_accesbase : Côté accès base
--			  @v_hauteur : Hauteur
--			  @v_largeur : Largeur
--			  @v_longueur : Longueur
--			  @v_position : Position
--			    0 : Tablier
--			    1 : Centrée
--			    2 : Bout de fourche
--			  @v_directCall : Appel direct
--			    Permet de ne pas compter deux fois les emplacements accessible par
--				les deux accès
-- Paramètre de sortie	: Capacité de stockage ou stockabilité
-- Descriptif		: Récupération de la capacité de stockage d'une adresse
--			  en fonction des dimensions d'une charge ou  de la stockabilité
--			  d'une charge sur une adresse
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[SPV_GETCHARGEADRESSE](@v_adr_idsysteme bigint, @v_adr_idbase bigint, @v_adr_idsousbase bigint,
	@v_tag_idtypeagv tinyint, @v_accesbase bit, @v_chg_idcharge_next int, @v_hauteur smallint, @v_largeur smallint, @v_longueur smallint,
	@v_position tinyint, @v_directCall bit)
	RETURNS smallint
AS
BEGIN

-- Déclaration des variables
DECLARE
	@v_error int,
	@v_status int,
	@v_retour int,
	@v_capacite smallint,
	@v_capacitecouche smallint,
	@v_bas_type_magasin tinyint,
	@v_bas_accumulation bit,
	@v_bas_gerbage bit,
	@v_tag_fourche smallint,
	@v_str_couche tinyint,
	@v_str_hauteur smallint,
	@v_str_longueur_debut_courante smallint,
	@v_str_longueur_fin_initiale smallint,
	@v_str_longueur_fin_courante smallint,
	@v_str_ecart_industriel smallint,
	@v_str_ecart_exploitation smallint,
	@v_str_offsetprofondeur int,
	@v_str_offsetniveau int,
	@v_chg_idcharge_last int,
	@v_chg_largeur smallint,
	@v_profondeur smallint,
	@v_rang smallint,
	@v_par_valeur varchar(128),
	@v_gerbage bit,
	@v_offsetprofondeur int,
	@v_couche tinyint,
	@v_fin smallint,
	@v_delta_debut smallint,
	@v_delta_fin smallint

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint

-- Déclaration des constantes de types de magasins
DECLARE
	@TYPE_INTERFACE tinyint,
	@TYPE_STOCK tinyint,
	@TYPE_PREPARATION tinyint

-- Déclaration des constantes d'options
DECLARE
	@OPTI_TABLIER tinyint,
	@OPTI_CENTREE tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @TYPE_INTERFACE = 2
	SET @TYPE_STOCK = 3
	SET @TYPE_PREPARATION = 4
	SET @OPTI_TABLIER = 0
	SET @OPTI_CENTREE = 1

-- Initialisation des variables
	SET @v_error = 0
	SET @v_status = @CODE_OK
	SET @v_retour = @CODE_KO

	SET @v_capacite = 0
	SELECT @v_tag_fourche = TAG_FOURCHE FROM TYPE_AGV WHERE TAG_ID = @v_tag_idtypeagv AND TAG_TYPE_OUTIL IN (1, 2)
	IF @v_tag_fourche IS NOT NULL
	BEGIN
		SELECT @v_bas_type_magasin = BAS_TYPE_MAGASIN, @v_bas_accumulation = BAS_ACCUMULATION, @v_bas_gerbage = BAS_GERBAGE
			FROM BASE WHERE BAS_SYSTEME = @v_adr_idsysteme AND BAS_BASE = @v_adr_idbase
		IF @v_bas_type_magasin IN (@TYPE_STOCK, @TYPE_PREPARATION) AND @v_bas_accumulation = 1
		BEGIN
			IF @v_longueur IS NOT NULL AND (@v_bas_gerbage = 0 OR (@v_bas_gerbage = 1 AND @v_hauteur IS NOT NULL))
				AND EXISTS (SELECT 1 FROM STRUCTURE WHERE STR_SYSTEME = @v_adr_idsysteme AND STR_BASE = @v_adr_idbase AND STR_SOUSBASE = @v_adr_idsousbase)
			BEGIN
				SET @v_profondeur = CASE WHEN @v_longueur >= @v_tag_fourche THEN @v_longueur ELSE
					CASE ISNULL(@v_position, @OPTI_TABLIER) WHEN @OPTI_CENTREE THEN @v_longueur + (@v_tag_fourche - @v_longueur) / 2
					WHEN @OPTI_TABLIER THEN @v_tag_fourche ELSE @v_longueur END END
				IF @v_longueur >= @v_tag_fourche
				BEGIN
					SET @v_delta_debut = 0
					SET @v_delta_fin = 0
				END
				ELSE
				BEGIN
					SET @v_delta_debut = @v_tag_fourche - @v_profondeur
					SET @v_delta_fin = CASE ISNULL(@v_position, @OPTI_TABLIER) WHEN @OPTI_CENTREE THEN (@v_tag_fourche - @v_longueur) / 2
						WHEN @OPTI_TABLIER THEN @v_tag_fourche - @v_longueur ELSE 0 END
				END
				IF ISNULL(@v_accesbase, 0) = 0
					SELECT TOP 1 @v_offsetprofondeur = CHG_POSY, @v_couche = CHG_COUCHE  FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase
						AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase AND CHG_TODESTROY = 0 ORDER BY CHG_POSY
				ELSE
					SELECT TOP 1 @v_offsetprofondeur = CHG_POSY + LONGUEUR, @v_couche = CHG_COUCHE FROM CHARGE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE, CHG_GABARIT, CHG_EMBALLAGE)
						WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase
						AND CHG_TODESTROY = 0 ORDER BY CHG_POSY + LONGUEUR DESC
				DECLARE c_structure CURSOR LOCAL FAST_FORWARD FOR SELECT A.STR_COUCHE, A.STR_HAUTEUR_COURANTE, A.STR_LONGUEUR_DEBUT_COURANTE,
					A.STR_LONGUEUR_FIN_INITIALE, A.STR_LONGUEUR_FIN_COURANTE, A.STR_ECART_EXPLOITATION, A.STR_ECART_INDUSTRIEL
					FROM STRUCTURE A WHERE A.STR_SYSTEME = @v_adr_idsysteme AND A.STR_BASE = @v_adr_idbase AND A.STR_SOUSBASE = @v_adr_idsousbase
					AND A.STR_AUTORISATION_DEPOSE = 1 AND NOT EXISTS (SELECT 1 FROM STRUCTURE B WHERE B.STR_SYSTEME = A.STR_SYSTEME AND B.STR_BASE = A.STR_BASE AND B.STR_SOUSBASE = A.STR_SOUSBASE
					AND B.STR_COUCHE < A.STR_COUCHE AND B.STR_AUTORISATION_DEPOSE = 0)
				OPEN c_structure
				FETCH NEXT FROM c_structure INTO @v_str_couche, @v_str_hauteur, @v_str_longueur_debut_courante, @v_str_longueur_fin_initiale, @v_str_longueur_fin_courante, @v_str_ecart_industriel, @v_str_ecart_exploitation
				WHILE @@FETCH_STATUS = 0
				BEGIN
					SET @v_capacitecouche = 0
					SET @v_chg_idcharge_last = NULL
					SET @v_rang = NULL
					SET @v_str_offsetniveau = NULL
					IF ISNULL(@v_accesbase, 0) = 0
					BEGIN
						IF EXISTS (SELECT 1 FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase
							AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase AND CHG_COUCHE = @v_str_couche AND CHG_TODESTROY = 0)
							SELECT TOP 1 @v_chg_idcharge_last = CHG_ID, @v_rang = CHG_RANG, @v_str_offsetprofondeur = CASE WHEN CHG_POSY > @v_str_longueur_fin_courante THEN @v_str_longueur_fin_courante ELSE CHG_POSY END
								FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase
								AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase AND CHG_COUCHE = @v_str_couche AND CHG_TODESTROY = 0
								ORDER BY CHG_POSY, CHG_POSZ DESC
						ELSE
							SET @v_str_offsetprofondeur = @v_str_longueur_fin_courante + @v_delta_fin + ISNULL(@v_str_ecart_exploitation, @v_str_ecart_industriel)
						IF @v_offsetprofondeur IS NOT NULL
						BEGIN
							IF @v_couche = @v_str_couche
								SET @v_str_offsetprofondeur = @v_offsetprofondeur
							ELSE
								SET @v_str_offsetprofondeur = CASE WHEN @v_str_offsetprofondeur - ISNULL(@v_str_ecart_exploitation, @v_str_ecart_industriel) - CASE WHEN @v_longueur >= @v_tag_fourche THEN @v_longueur ELSE @v_tag_fourche END > @v_offsetprofondeur THEN @v_offsetprofondeur + CASE WHEN @v_longueur >= @v_tag_fourche THEN @v_longueur ELSE @v_tag_fourche END ELSE @v_str_offsetprofondeur END
						END
						-- Retrait du @v_delta_debut car le point de navigation doit se trouver sur le tronçon
						IF @v_str_offsetprofondeur > @v_str_longueur_debut_courante
							SET @v_capacitecouche = (@v_str_offsetprofondeur - @v_str_longueur_debut_courante - CASE WHEN @v_str_longueur_debut_courante > @v_delta_debut THEN 0 ELSE @v_delta_debut - @v_str_longueur_debut_courante END) / (ISNULL(@v_str_ecart_exploitation, @v_str_ecart_industriel) + @v_profondeur)
					END
					ELSE
					BEGIN
						IF EXISTS (SELECT 1 FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase
							AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase AND CHG_COUCHE = @v_str_couche AND CHG_TODESTROY = 0)
							SELECT TOP 1 @v_chg_idcharge_last = CHG_ID, @v_rang = CHG_RANG, @v_str_offsetprofondeur = CASE WHEN CHG_POSY + LONGUEUR < @v_str_longueur_debut_courante THEN @v_str_longueur_debut_courante ELSE CHG_POSY + LONGUEUR END
								FROM CHARGE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE, CHG_GABARIT, CHG_EMBALLAGE)
								WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase
								AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase AND CHG_COUCHE = @v_str_couche AND CHG_TODESTROY = 0
								ORDER BY CHG_POSY DESC, CHG_POSZ DESC
						ELSE
							SET @v_str_offsetprofondeur = @v_str_longueur_debut_courante - @v_delta_fin - ISNULL(@v_str_ecart_exploitation, @v_str_ecart_industriel)
						IF @v_offsetprofondeur IS NOT NULL
						BEGIN
							IF ((@v_couche = @v_str_couche AND @v_directCall = 0) OR (ISNULL(@v_accesbase, 0) = 1 AND @v_directCall = 1))
								SET @v_str_offsetprofondeur = @v_offsetprofondeur
							ELSE
								SET @v_str_offsetprofondeur = CASE WHEN @v_str_offsetprofondeur + ISNULL(@v_str_ecart_exploitation, @v_str_ecart_industriel) + CASE WHEN @v_longueur >= @v_tag_fourche THEN @v_longueur ELSE @v_tag_fourche END < @v_offsetprofondeur THEN @v_offsetprofondeur - CASE WHEN @v_longueur >= @v_tag_fourche THEN @v_longueur ELSE @v_tag_fourche END ELSE @v_str_offsetprofondeur END
						END
						-- Pas de retrait du @v_delta_debut car on suppose que le tronçon est suffisemment long
						IF @v_str_offsetprofondeur < @v_str_longueur_fin_courante
							SET @v_capacitecouche = (@v_str_longueur_fin_courante - @v_str_offsetprofondeur ) / (ISNULL(@v_str_ecart_exploitation, @v_str_ecart_industriel) + @v_profondeur)
					END
					IF @v_bas_gerbage = 1
					BEGIN
						SELECT @v_str_offsetniveau = (SELECT SUM(ISNULL(CHG_HAUTEUR, ISNULL(GBR_HAUTEUR, EMB_HAUTEUR))) FROM CHARGE LEFT OUTER JOIN GABARIT ON GBR_ID = CHG_GABARIT
							LEFT OUTER JOIN EMBALLAGE ON EMB_ID = CHG_EMBALLAGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase
							AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase AND CHG_TODESTROY = 0 AND CHG_COUCHE = @v_str_couche AND CHG_RANG = @v_rang)
						SET @v_capacitecouche = @v_capacitecouche * (@v_str_hauteur / @v_hauteur)
						IF @v_chg_idcharge_next IS NOT NULL
						BEGIN
							IF @v_chg_idcharge_last IS NOT NULL
							BEGIN
								SET @v_gerbage = 0
								-- Récupération de la fonction d'évalution des conditions de gerbage
								SELECT @v_par_valeur = CASE PAR_VAL WHEN '' THEN NULL ELSE PAR_VAL END FROM PARAMETRE WHERE PAR_NOM = 'EVALUE_GERBAGE'
								IF (@v_par_valeur IS NOT NULL)
								BEGIN
									EXEC @v_gerbage = @v_par_valeur @v_chg_idcharge_last, @v_chg_idcharge_next
									SET @v_error = @@ERROR
								END
								ELSE
									SET @v_gerbage = 1
								IF @v_status = @CODE_OK AND @v_error = 0 AND @v_gerbage = 1
									SET @v_capacitecouche = @v_capacitecouche + ((@v_str_hauteur - @v_str_offsetniveau) / @v_hauteur)
							END
						END
						ELSE
							IF @v_str_offsetniveau IS NOT NULL AND ((ISNULL(@v_accesbase, 0) = 0 AND @v_directCall = 1) OR (@v_directCall = 0))
								SET @v_capacitecouche = @v_capacitecouche + ((@v_str_hauteur - @v_str_offsetniveau) / @v_hauteur)
					END
					SET @v_capacite = @v_capacite + @v_capacitecouche
					IF @v_chg_idcharge_next IS NOT NULL AND @v_capacite >= 1
						BREAK
					FETCH NEXT FROM c_structure INTO @v_str_couche, @v_str_hauteur, @v_str_longueur_debut_courante, @v_str_longueur_fin_initiale, @v_str_longueur_fin_courante, @v_str_ecart_industriel, @v_str_ecart_exploitation
				END
				CLOSE c_structure
				DEALLOCATE c_structure
			END
		END
		ELSE IF ((@v_bas_type_magasin = @TYPE_INTERFACE) OR (@v_bas_type_magasin = @TYPE_STOCK AND @v_bas_accumulation = 0))
			SELECT @v_capacite = CASE WHEN NOT EXISTS (SELECT 1 FROM INT_CHARGE_VIVANTE WHERE CHG_IDSYSTEME = @v_adr_idsysteme AND CHG_IDBASE = @v_adr_idbase AND CHG_IDSOUSBASE = @v_adr_idsousbase)
				THEN 1 ELSE 0 END
	END
	RETURN @v_capacite
END

SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procedure		: SPV_OFFSETADRESSE
-- Paramètre d'entrée	: @v_tag_idtypeagv : Identifiant type AGV
--			  @v_adr_idsysteme : Clé système
--			  @v_adr_idbase : Clé base
--			  @v_adr_idsousbase : Clé sous-base
--			  @v_adr_niveau : Niveau
--			  @v_accesbase : Côté accès base
--			  @v_bas_type_magasin : Type magasin
--			  @v_bas_rayonnage : Rayonnage
--			  @v_bas_gerbage : Gerbage
--			  @v_bas_emplacement : Emplacement
--			  @v_chg_idcharge : Identifiant charge
--			  @v_hauteur : Hauteur
--			  @v_longueur : Longueur
--			  @v_chg_position : Position
--			    0 : Tablier
--			    1 : Centrée
--			    2 : Bout de fourche
--			  @v_forcage : Forçage
-- Paramètre de sortie	: RETOUR :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
--			    @CODE_KO_INCOMPATIBLE : Absence longueur fourche
--			    @CODE_KO_INATTENDU : Absence données dimensionnelles
--			    @CODE_KO_PLEIN : Adresse pleine
--			    @CODE_KO_SPECIFIQUE : Echec évaluation conditions gerbage
--			    @CODE_KO_ACTION_INCONNUE : Action inconnue
--			  OFFSETPROFONDEUR : Offset profondeur
--			  OFFSETNIVEAU : Offset niveau
--			  OFFSETCOLONNE : Offset colonne
-- Descriptif		: Calcul des offsets sur une adresse
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[SPV_OFFSETADRESSE](@v_tag_idtypeagv tinyint, @v_adr_idsysteme bigint, @v_adr_idbase bigint,
	@v_adr_idsousbase bigint, @v_adr_niveau tinyint, @v_accesbase bit, @v_bas_type_magasin tinyint, @v_bas_rayonnage bit, @v_bas_gerbage bit,
	@v_bas_emplacement bit, @v_chg_idcharge_next int, @v_hauteur smallint, @v_longueur smallint, @v_chg_position tinyint, @v_forcage bit)
	RETURNS @offsetadresse TABLE (RETOUR int NOT NULL, OFFSETPROFONDEUR int NULL, OFFSETNIVEAU int NULL, OFFSETCOLONNE int NULL)
AS
BEGIN

-- Déclaration des variables
DECLARE
	@v_error int,
	@v_status int,
	@v_retour int,
	@v_par_valeur varchar(128),
	@v_tag_fourche smallint,
	@v_str_couche tinyint,
	@v_str_hauteur smallint,
	@v_str_longueur_debut smallint,
	@v_str_longueur_fin smallint,
	@v_str_cote smallint,
	@v_str_ecart smallint,
	@v_profondeur smallint,
	@v_rang smallint,
	@v_chg_idcharge_last int,
	@v_gerbage bit,
	@v_offsetprofondeur int,
	@v_offsetniveau int,
	@v_offsetcolonne int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_INCOMPATIBLE tinyint,
	@CODE_KO_INATTENDU tinyint,
	@CODE_KO_PLEIN tinyint,
	@CODE_KO_SPECIFIQUE tinyint,
	@CODE_KO_ACTION_INCONNUE tinyint

-- Déclaration des constantes de types de magasins
DECLARE
	@TYPE_STOCK tinyint,
	@TYPE_PREPARATION tinyint

-- Déclaration des constantes d'options
DECLARE
	@OPTI_TABLIER tinyint,
	@OPTI_CENTREE tinyint,
	@OPTI_FOURCHE tinyint

-- Déclaration des constantes d'actions
DECLARE
	@ACTI_PRISE smallint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_INCOMPATIBLE = 14
	SET @CODE_KO_INATTENDU = 16
	SET @CODE_KO_PLEIN = 17
	SET @CODE_KO_SPECIFIQUE = 20
	SET @CODE_KO_ACTION_INCONNUE = 29
	SET @TYPE_STOCK = 3
	SET @TYPE_PREPARATION = 4
	SET @OPTI_TABLIER = 0
	SET @OPTI_CENTREE = 1
	SET @OPTI_FOURCHE = 2
	SET @ACTI_PRISE = 2

-- Initialisation des variables
	SET @v_error = 0
	SET @v_status = @CODE_OK
	SET @v_retour = @CODE_KO

	-- Vérification des informations AGV
	IF @v_tag_idtypeagv IS NULL
		SELECT TOP 1 @v_tag_fourche = TAG_FOURCHE FROM TYPE_AGV WHERE TAG_TYPE_OUTIL IN (1, 2) ORDER BY TAG_FOURCHE DESC
	ELSE
		SELECT @v_tag_fourche = TAG_FOURCHE FROM TYPE_AGV WHERE TAG_ID = @v_tag_idtypeagv AND TAG_TYPE_OUTIL IN (1, 2)
	IF @v_tag_fourche IS NOT NULL
	BEGIN
		-- Contrôle de la position
		IF EXISTS (SELECT 1 FROM OPTION_ACTION WHERE OPA_ACTION = @ACTI_PRISE AND OPA_ID = ISNULL(@v_chg_position, @OPTI_TABLIER))
		BEGIN
			IF ((@v_bas_gerbage = 1 AND @v_hauteur IS NOT NULL) OR @v_bas_gerbage = 0) AND @v_longueur IS NOT NULL
			BEGIN
				-- Détermination de la couche et de l'emplacement approprié de stockage ou de préparation
				IF EXISTS (SELECT 1 FROM STRUCTURE WHERE STR_SYSTEME = @v_adr_idsysteme
					AND STR_BASE = @v_adr_idbase AND STR_SOUSBASE = @v_adr_idsousbase
					AND STR_LONGUEUR_FIN_COURANTE IS NOT NULL AND ((@v_bas_gerbage = 1 AND STR_HAUTEUR_COURANTE IS NOT NULL) OR (@v_bas_gerbage = 0))
					AND ((STR_AUTORISATION_DEPOSE = 1) OR (@v_forcage = 1)))
				BEGIN
					IF @v_bas_emplacement = 1 AND EXISTS (SELECT 1 FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase
						AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase AND CHG_TODESTROY = 0)
					BEGIN
						SET @v_profondeur = CASE WHEN @v_longueur >= @v_tag_fourche THEN @v_longueur ELSE
							CASE ISNULL(@v_chg_position, @OPTI_TABLIER) WHEN @OPTI_CENTREE THEN @v_longueur + (@v_tag_fourche - @v_longueur) / 2
							WHEN @OPTI_FOURCHE THEN @v_longueur ELSE @v_tag_fourche END END
						IF ((@v_bas_type_magasin = @TYPE_PREPARATION) OR (@v_bas_type_magasin = @TYPE_STOCK AND @v_bas_rayonnage = 0 AND @v_bas_gerbage = 0))
						BEGIN
							-- Préparation ou stock sans rayonnage, sans gerbage
							SET @v_str_couche = 1
							SELECT @v_offsetniveau = STR_COTE, @v_str_hauteur = STR_HAUTEUR_COURANTE, @v_str_ecart = ISNULL(STR_ECART_EXPLOITATION, STR_ECART_INDUSTRIEL),
								@v_str_longueur_debut = STR_LONGUEUR_DEBUT_COURANTE, @v_str_longueur_fin = STR_LONGUEUR_FIN_COURANTE,
								@v_offsetcolonne = 0
								FROM STRUCTURE WHERE STR_SYSTEME = @v_adr_idsysteme AND STR_BASE = @v_adr_idbase AND STR_SOUSBASE = @v_adr_idsousbase
								AND STR_COUCHE = @v_str_couche AND ((STR_AUTORISATION_DEPOSE = 1) OR (@v_forcage = 1))
							IF ISNULL(@v_accesbase, 0) = 0
								SELECT TOP 1 @v_offsetprofondeur = CHG_POSY - @v_str_ecart - @v_profondeur FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase
									AND CHG_TODESTROY = 0 AND CHG_COUCHE = @v_str_couche ORDER BY CHG_POSY
							ELSE
								SELECT TOP 1 @v_offsetprofondeur = CHG_POSY + LONGUEUR + @v_str_ecart + @v_profondeur - @v_longueur FROM CHARGE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE, CHG_GABARIT, CHG_EMBALLAGE)
									WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase
									AND CHG_TODESTROY = 0 AND CHG_COUCHE = @v_str_couche ORDER BY CHG_POSY DESC
							IF (@v_offsetprofondeur + @v_longueur) > @v_str_longueur_fin
							BEGIN
								IF ISNULL(@v_accesbase, 0) = 0
									SET @v_offsetprofondeur = @v_str_longueur_fin - @v_longueur
								ELSE
									SET @v_status = @CODE_KO_PLEIN
							END
						END
						ELSE IF @v_bas_type_magasin = @TYPE_STOCK AND @v_bas_rayonnage = 0 AND @v_bas_gerbage = 1
						BEGIN
							-- Stock sans rayonnage avec gerbage
							SET @v_str_couche = 1
							SET @v_gerbage = 0
							SELECT @v_str_cote = STR_COTE, @v_str_hauteur = STR_HAUTEUR_COURANTE, @v_str_ecart = ISNULL(STR_ECART_EXPLOITATION, STR_ECART_INDUSTRIEL),
								@v_offsetprofondeur = CASE WHEN ISNULL(@v_accesbase, 0) = 0 THEN STR_LONGUEUR_FIN_COURANTE - @v_longueur ELSE STR_LONGUEUR_DEBUT_COURANTE END,
								@v_str_longueur_debut = STR_LONGUEUR_DEBUT_COURANTE, @v_str_longueur_fin = STR_LONGUEUR_FIN_COURANTE
								FROM STRUCTURE WHERE STR_SYSTEME = @v_adr_idsysteme AND STR_BASE = @v_adr_idbase AND STR_SOUSBASE = @v_adr_idsousbase
								AND STR_COUCHE = @v_str_couche AND ((STR_AUTORISATION_DEPOSE = 1) OR (@v_forcage = 1))
							IF ISNULL(@v_accesbase, 0) = 0
								SELECT TOP 1 @v_chg_idcharge_last = CHG_ID, @v_offsetprofondeur = CHG_POSY, @v_rang = CHG_RANG FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase
									AND CHG_TODESTROY = 0 AND CHG_COUCHE = @v_str_couche ORDER BY CHG_POSY, CHG_POSZ DESC
							ELSE
								SELECT TOP 1 @v_chg_idcharge_last = CHG_ID, @v_offsetprofondeur = CHG_POSY + LONGUEUR, @v_rang = CHG_RANG FROM CHARGE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE, CHG_GABARIT, CHG_EMBALLAGE)
									WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase
									AND CHG_TODESTROY = 0 AND CHG_COUCHE = @v_str_couche ORDER BY CHG_POSY + LONGUEUR DESC , CHG_POSZ DESC
							SELECT @v_offsetniveau = SUM(ISNULL(CHG_HAUTEUR, ISNULL(GBR_HAUTEUR, EMB_HAUTEUR)))
								FROM CHARGE LEFT OUTER JOIN GABARIT ON GBR_ID = CHG_GABARIT
								LEFT OUTER JOIN EMBALLAGE ON EMB_ID = CHG_EMBALLAGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase
								AND CHG_TODESTROY = 0 AND CHG_COUCHE = @v_str_couche AND CHG_RANG = @v_rang
							SELECT TOP 1 @v_offsetcolonne = CHG_POSX
								FROM CHARGE LEFT OUTER JOIN GABARIT ON GBR_ID = CHG_GABARIT
								LEFT OUTER JOIN EMBALLAGE ON EMB_ID = CHG_EMBALLAGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase
								AND CHG_TODESTROY = 0 AND CHG_COUCHE = @v_str_couche AND CHG_RANG = @v_rang ORDER BY ABS(CHG_POSX)
							IF ((@v_offsetniveau + @v_hauteur) <= @v_str_hauteur
								AND NOT EXISTS (SELECT 1 FROM INT_MISSION_VIVANTE WHERE MIS_IDCHARGE = @v_chg_idcharge_last))
							BEGIN
								-- Récupération de la fonction d'évalution des conditions de gerbage
								SELECT @v_par_valeur = CASE PAR_VAL WHEN '' THEN NULL ELSE PAR_VAL END FROM PARAMETRE WHERE PAR_NOM = 'EVALUE_GERBAGE'
								IF (@v_par_valeur IS NOT NULL)
								BEGIN
									EXEC @v_gerbage = @v_par_valeur @v_chg_idcharge_last, @v_chg_idcharge_next
									SET @v_error = @@ERROR
								END
								ELSE
									SET @v_gerbage = 1
							END
							IF @v_status = @CODE_OK AND @v_error = 0
							BEGIN
								IF @v_gerbage = 0
								BEGIN
									SET @v_offsetniveau = @v_str_cote
									SET @v_offsetcolonne = 0
								END
								IF ISNULL(@v_accesbase, 0) = 0
									SELECT TOP 1 @v_offsetprofondeur = CASE WHEN CHG_POSY - @v_str_ecart - @v_profondeur > @v_offsetprofondeur THEN @v_offsetprofondeur ELSE CHG_POSY - @v_str_ecart - @v_profondeur END
										FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase
										AND CHG_TODESTROY = 0 AND CHG_COUCHE = @v_str_couche AND CHG_RANG = CASE @v_gerbage WHEN 0 THEN @v_rang ELSE @v_rang - 1 END ORDER BY CHG_POSY
								ELSE
								BEGIN
									IF EXISTS (SELECT 1 FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase
										AND CHG_TODESTROY = 0 AND CHG_COUCHE = @v_str_couche AND CHG_RANG = CASE @v_gerbage WHEN 0 THEN @v_rang ELSE @v_rang + 1 END)
										SELECT TOP 1 @v_offsetprofondeur = CASE WHEN CHG_POSY + LONGUEUR + @v_str_ecart + @v_profondeur < @v_offsetprofondeur THEN @v_offsetprofondeur ELSE CHG_POSY + LONGUEUR + @v_str_ecart + @v_profondeur END - @v_longueur FROM CHARGE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE, CHG_GABARIT, CHG_EMBALLAGE)
											WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase
											AND CHG_TODESTROY = 0 AND CHG_COUCHE = @v_str_couche AND CHG_RANG = CASE @v_gerbage WHEN 0 THEN @v_rang ELSE @v_rang + 1 END ORDER BY CHG_POSY + LONGUEUR DESC
									ELSE
										SET @v_offsetprofondeur = @v_offsetprofondeur - @v_longueur
								END
								IF (@v_offsetprofondeur + @v_longueur) > @v_str_longueur_fin
								BEGIN
									IF ISNULL(@v_accesbase, 0) = 0
										SET @v_offsetprofondeur = @v_str_longueur_fin - @v_longueur
									ELSE
										SET @v_status = @CODE_KO_PLEIN
								END				
								IF @v_offsetprofondeur < @v_str_longueur_debut
								BEGIN
									IF ISNULL(@v_accesbase, 0) = 1
										SET @v_offsetprofondeur = @v_str_longueur_debut
								END				
							END
							ELSE
								SET @v_status = @CODE_KO_SPECIFIQUE
						END
						ELSE
						BEGIN
							-- Stock avec rayonnage
							IF ISNULL(@v_accesbase, 0) = 0
							BEGIN
								SELECT TOP 1 @v_offsetprofondeur = CHG_POSY FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase
									AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase AND CHG_TODESTROY = 0 ORDER BY CHG_POSY
								SELECT TOP 1 @v_offsetniveau = STR_COTE, @v_str_hauteur = STR_HAUTEUR_COURANTE,
									@v_offsetprofondeur = CASE WHEN CHG_POSY > @v_offsetprofondeur THEN @v_offsetprofondeur ELSE CHG_POSY END,
									@v_str_longueur_debut = STR_LONGUEUR_DEBUT_COURANTE, @v_str_longueur_fin = STR_LONGUEUR_FIN_COURANTE,
									@v_offsetcolonne = 0
									FROM (SELECT B.STR_COTE, B.STR_LONGUEUR_DEBUT_INITIALE, B.STR_LONGUEUR_FIN_INITIALE, B.STR_HAUTEUR_COURANTE, ISNULL((SELECT TOP 1 CHG_POSY - ISNULL(B.STR_ECART_EXPLOITATION, B.STR_ECART_INDUSTRIEL) - @v_profondeur FROM CHARGE
									WHERE CHG_ADR_KEYSYS = STR_SYSTEME AND CHG_ADR_KEYBASE = STR_BASE AND CHG_ADR_KEYSSBASE = STR_SOUSBASE AND CHG_TODESTROY = 0 AND CHG_COUCHE = STR_COUCHE ORDER BY CHG_POSY), B.STR_LONGUEUR_FIN_COURANTE - @v_longueur) CHG_POSY,
									B.STR_LONGUEUR_DEBUT_COURANTE, B.STR_LONGUEUR_FIN_COURANTE FROM STRUCTURE B WHERE B.STR_SYSTEME = @v_adr_idsysteme AND B.STR_BASE = @v_adr_idbase AND B.STR_SOUSBASE = @v_adr_idsousbase
									AND ((@v_adr_niveau IS NULL) OR (@v_adr_niveau IS NOT NULL AND B.STR_COUCHE = @v_adr_niveau)) AND ((B.STR_AUTORISATION_DEPOSE = 1) OR (@v_forcage = 1))
									AND NOT EXISTS (SELECT 1 FROM STRUCTURE C WHERE C.STR_SYSTEME = B.STR_SYSTEME AND C.STR_BASE = B.STR_BASE AND C.STR_SOUSBASE = B.STR_SOUSBASE
									AND C.STR_COUCHE < B.STR_COUCHE AND C.STR_AUTORISATION_DEPOSE = 0)) A
									WHERE CASE WHEN CHG_POSY > @v_offsetprofondeur THEN @v_offsetprofondeur ELSE CHG_POSY END + @v_longueur <= STR_LONGUEUR_FIN_COURANTE AND CASE WHEN CHG_POSY > @v_offsetprofondeur THEN @v_offsetprofondeur ELSE CHG_POSY END >= STR_LONGUEUR_DEBUT_COURANTE
									ORDER BY CASE WHEN CHG_POSY > @v_offsetprofondeur THEN @v_offsetprofondeur ELSE CHG_POSY END DESC, STR_COTE
							END
							ELSE
							BEGIN
								SELECT TOP 1 @v_offsetprofondeur = CHG_POSY + LONGUEUR FROM CHARGE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE, CHG_GABARIT, CHG_EMBALLAGE)
									WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase
									AND CHG_TODESTROY = 0 ORDER BY CHG_POSY + LONGUEUR DESC
								SELECT TOP 1 @v_offsetniveau = STR_COTE, @v_str_hauteur = STR_HAUTEUR_COURANTE,
									@v_offsetprofondeur = CASE WHEN CHG_POSY < @v_offsetprofondeur THEN @v_offsetprofondeur ELSE CHG_POSY END - @v_longueur,
									@v_str_longueur_debut = STR_LONGUEUR_DEBUT_COURANTE, @v_str_longueur_fin = STR_LONGUEUR_FIN_COURANTE,
									@v_offsetcolonne = 0
									FROM (SELECT B.STR_COTE, B.STR_LONGUEUR_DEBUT_INITIALE, B.STR_LONGUEUR_FIN_INITIALE, B.STR_HAUTEUR_COURANTE, ISNULL((SELECT TOP 1 CHG_POSY + LONGUEUR + ISNULL(B.STR_ECART_EXPLOITATION, B.STR_ECART_INDUSTRIEL) + @v_profondeur FROM CHARGE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE, CHG_GABARIT, CHG_EMBALLAGE)
									WHERE CHG_ADR_KEYSYS = STR_SYSTEME AND CHG_ADR_KEYBASE = STR_BASE AND CHG_ADR_KEYSSBASE = STR_SOUSBASE AND CHG_TODESTROY = 0 AND CHG_COUCHE = STR_COUCHE ORDER BY CHG_POSY DESC), B.STR_LONGUEUR_DEBUT_COURANTE + @v_longueur) CHG_POSY, B.STR_LONGUEUR_DEBUT_COURANTE,
									B.STR_LONGUEUR_FIN_COURANTE FROM STRUCTURE B WHERE B.STR_SYSTEME = @v_adr_idsysteme AND B.STR_BASE = @v_adr_idbase AND B.STR_SOUSBASE = @v_adr_idsousbase
									AND ((@v_adr_niveau IS NULL) OR (@v_adr_niveau IS NOT NULL AND B.STR_COUCHE = @v_adr_niveau)) AND ((B.STR_AUTORISATION_DEPOSE = 1) OR (@v_forcage = 1))
									AND NOT EXISTS (SELECT 1 FROM STRUCTURE C WHERE C.STR_SYSTEME = B.STR_SYSTEME AND C.STR_BASE = B.STR_BASE AND C.STR_SOUSBASE = B.STR_SOUSBASE
									AND C.STR_COUCHE < B.STR_COUCHE AND C.STR_AUTORISATION_DEPOSE = 0)) A
									WHERE CASE WHEN CHG_POSY < @v_offsetprofondeur THEN @v_offsetprofondeur ELSE CHG_POSY END <= STR_LONGUEUR_FIN_COURANTE AND CASE WHEN CHG_POSY < @v_offsetprofondeur THEN @v_offsetprofondeur ELSE CHG_POSY END + @v_longueur >= STR_LONGUEUR_DEBUT_COURANTE
									ORDER BY CASE WHEN CHG_POSY < @v_offsetprofondeur THEN @v_offsetprofondeur ELSE CHG_POSY END, STR_COTE									
							END
						END
					END
					ELSE IF @v_bas_emplacement = 1
					BEGIN
						SET @v_str_couche = 1
						SELECT @v_offsetniveau = STR_COTE, @v_str_hauteur = STR_HAUTEUR_COURANTE,
							@v_offsetprofondeur = CASE WHEN ISNULL(@v_accesbase, 0) = 0 THEN STR_LONGUEUR_FIN_COURANTE - @v_longueur ELSE STR_LONGUEUR_DEBUT_COURANTE END,
							@v_str_longueur_debut = STR_LONGUEUR_DEBUT_COURANTE, @v_str_longueur_fin = STR_LONGUEUR_FIN_COURANTE,
							@v_offsetcolonne = 0
							FROM STRUCTURE WHERE STR_SYSTEME = @v_adr_idsysteme AND STR_BASE = @v_adr_idbase AND STR_SOUSBASE = @v_adr_idsousbase
							AND ((@v_adr_niveau IS NULL AND STR_COUCHE = @v_str_couche) OR (@v_adr_niveau IS NOT NULL AND STR_COUCHE = @v_adr_niveau))
					END
					ELSE IF @v_bas_emplacement = 0
					BEGIN
						SET @v_str_couche = 1
						SELECT @v_offsetniveau = STR_COTE, @v_str_hauteur = STR_HAUTEUR_COURANTE,
							@v_offsetprofondeur = CASE WHEN ISNULL(@v_accesbase, 0) = 0 THEN STR_LONGUEUR_FIN_COURANTE ELSE STR_LONGUEUR_DEBUT_COURANTE END,
							@v_str_longueur_debut = STR_LONGUEUR_DEBUT_COURANTE, @v_str_longueur_fin = STR_LONGUEUR_FIN_COURANTE,
							@v_offsetcolonne = 0
							FROM STRUCTURE WHERE STR_SYSTEME = @v_adr_idsysteme AND STR_BASE = @v_adr_idbase AND STR_SOUSBASE = @v_adr_idsousbase
							AND ((@v_adr_niveau IS NULL AND STR_COUCHE = @v_str_couche) OR (@v_adr_niveau IS NOT NULL AND STR_COUCHE = @v_adr_niveau))
					END
					IF @v_status = @CODE_OK
					BEGIN
						IF @v_offsetprofondeur >= @v_str_longueur_debut AND ((@v_offsetniveau >= 0 AND @v_str_hauteur IS NULL)
							OR ((@v_offsetniveau + @v_hauteur) <= @v_str_hauteur AND @v_str_hauteur IS NOT NULL))
							SET @v_status = @CODE_OK
						ELSE
							SET @v_status = @CODE_KO_PLEIN
					END
				END
				ELSE
					SET @v_status = @CODE_KO_INATTENDU
			END
			ELSE
				SET @v_status = @CODE_KO_INATTENDU
		END
		ELSE
			SET @v_status = @CODE_KO_ACTION_INCONNUE
	END
	ELSE
		SET @v_status = @CODE_KO_INCOMPATIBLE
	SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END

	INSERT INTO @offsetadresse SELECT @v_retour, @v_offsetprofondeur, @v_offsetniveau, @v_offsetcolonne
	RETURN
END

SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON


-----------------------------------------------------------------------------------------
-- Fonction		: SPV_OPTIMISATIONINDEX
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: 
-- Descriptif		: Optimisation des index
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[SPV_OPTIMISATIONINDEX]()
	RETURNS varchar(8000)
AS
BEGIN

-- Déclaration des variables
DECLARE
	@v_sql varchar(8000)

	SET @v_sql = '
		DECLARE
			@v_error int,
			@v_status int,
			@v_retour int,
			@v_commande varchar(8000),
			@v_schema sysname,
			@v_table sysname,
			@v_objectname char(255),
			@v_objectid int,
			@v_indexid int,
			@v_logicalfragmentation decimal

		DECLARE
			@CODE_OK tinyint,
			@CODE_KO tinyint

		DECLARE
			@DEFRAGMENTATION tinyint,
			@RECONSTRUCTION tinyint

			SET @CODE_OK = 0
			SET @CODE_KO = 1
			SET @DEFRAGMENTATION = 10
			SET @RECONSTRUCTION = 40

			SET @v_error = 0
			SET @v_status = @CODE_OK
			SET @v_retour = @CODE_KO

			CREATE TABLE #Tmp(OBJECTNAME char(255), OBJECTID int, INDEXNAME char(255), INDEXID int, LEVEL int, PAGES int,
				ROWS int, MINIMUMRECORDSIZE int, MAXIMUMRECORDSIZE int, AVERAGERECORDSIZE int, FORWARDEDRECORDS int, EXTENTS int, EXTENTSWITCHES int,
				AVERAGEFREEBYTES int, AVERAGEPAGEDENSITY int, SCANDENSITY decimal, BESTCOUNT int, ACTUALCOUNT int, LOGICALFRAGMENTATION decimal,
				EXTENTFRAGMENTATION decimal)
			DECLARE c_index CURSOR LOCAL FAST_FORWARD FOR SELECT s.name, t.name FROM sys.tables t INNER JOIN sys.schemas s ON s.schema_id = t.schema_id WHERE t.type = ''U'' AND t.is_ms_shipped = 0
			OPEN c_index
			FETCH NEXT FROM c_index INTO @v_schema, @v_table
			WHILE ((@@FETCH_STATUS = 0) AND (@v_status = @CODE_OK) AND (@v_error = 0))
			BEGIN
				INSERT INTO #Tmp EXEC (''DBCC SHOWCONTIG ('''''' + @v_schema + ''.'' + @v_table + '''''') WITH FAST, TABLERESULTS, ALL_INDEXES, NO_INFOMSGS'')
				FETCH NEXT FROM c_index INTO @v_schema, @v_table
			END
			CLOSE c_index
			DEALLOCATE c_index
			DECLARE c_index CURSOR LOCAL FAST_FORWARD FOR SELECT OBJECTNAME, OBJECTID, INDEXID, LOGICALFRAGMENTATION, s.name FROM #Tmp INNER JOIN sys.tables t ON t.object_id = OBJECTID
				INNER JOIN sys.schemas s ON s.schema_id = t.schema_id, sysindexes i, sysobjects o
				WHERE INDEXPROPERTY(OBJECTID, INDEXNAME, ''IndexDepth'') > 0 AND i.id = OBJECTID AND indid = INDEXID AND o.id = i.id
			OPEN c_index
			FETCH NEXT FROM c_index INTO @v_objectname, @v_objectid, @v_indexid, @v_logicalfragmentation, @v_schema
			WHILE @@FETCH_STATUS = 0
			BEGIN
				IF @v_logicalfragmentation > @DEFRAGMENTATION
				BEGIN
					IF @v_logicalfragmentation < @RECONSTRUCTION
						SET @v_commande = ''DBCC INDEXDEFRAG (0, '' + LTRIM(RTRIM(@v_objectid)) + '', '' + LTRIM(RTRIM(@v_indexid)) + '') WITH NO_INFOMSGS''
					ELSE
						SET @v_commande = ''DBCC DBREINDEX ('''''' + LTRIM(RTRIM(@v_schema)) + ''.'' + LTRIM(RTRIM(@v_objectname)) + '''''', '''''''') WITH NO_INFOMSGS''
					EXEC (@v_commande)
				END
				FETCH NEXT FROM c_index INTO @v_objectname, @v_objectid, @v_indexid, @v_logicalfragmentation, @v_schema
			END
			CLOSE c_index
			DEALLOCATE c_index
			DROP TABLE #Tmp'
	RETURN @v_sql
END

SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procedure		: SPV_POSITIONCHARGE
-- Paramètre d'entrée	: @v_tag_idtypeagv : Identifiant type AGV
--			  @v_adr_idsysteme : Clé système
--			  @v_adr_idbase : Clé base
--			  @v_adr_idsousbase : Clé sous-base
--			  @v_accesbase : Côté accès base
--			  @v_bas_gerbage : Gerbage
--			  @v_hauteur : Hauteur
--			  @v_longueur : Longueur
--			  @v_chg_position : Position
--			    0 : Tablier
--			    1 : Centrée
--			    2 : Bout de fourche
-- Paramètre de sortie	: PROFONDEUR : Offset profondeur
--			  NIVEAU : Offset niveau
--			  COUCHE : Couche
--			  RANG : Rang
-- Descriptif		: Calcul des positions d'une charge
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[SPV_POSITIONCHARGE](@v_tag_idtypeagv tinyint, @v_adr_idsysteme bigint, @v_adr_idbase bigint,
	@v_adr_idsousbase bigint, @v_accesbase bit, @v_bas_gerbage bit, @v_hauteur smallint, @v_longueur smallint, @v_chg_position tinyint,
	@v_chg_positionprofondeur smallint, @v_chg_positionniveau smallint)
	RETURNS @positioncharge TABLE (PROFONDEUR smallint NULL, NIVEAU smallint NULL, COUCHE tinyint NULL, RANG smallint NULL)
AS
BEGIN

-- Déclaration des variables
DECLARE
	@v_tag_fourche smallint,
	@v_couche tinyint,
	@v_rang smallint,
	@v_delta smallint

-- Déclaration des constantes d'options
DECLARE
	@OPTI_TABLIER tinyint,
	@OPTI_CENTREE tinyint,
	@OPTI_FOURCHE tinyint

-- Définition des constantes
	SET @OPTI_TABLIER = 0
	SET @OPTI_CENTREE = 1
	SET @OPTI_FOURCHE = 2

	-- Vérification des informations AGV
	IF @v_tag_idtypeagv IS NULL
		SELECT TOP 1 @v_tag_fourche = TAG_FOURCHE FROM TYPE_AGV WHERE TAG_TYPE_OUTIL IN (1, 2) ORDER BY TAG_FOURCHE DESC
	ELSE
		SELECT @v_tag_fourche = TAG_FOURCHE FROM TYPE_AGV WHERE TAG_ID = @v_tag_idtypeagv AND TAG_TYPE_OUTIL IN (1, 2)
	IF @v_tag_fourche IS NOT NULL
	BEGIN
		IF @v_longueur < @v_tag_fourche AND ISNULL(@v_chg_position, @OPTI_TABLIER) IN (@OPTI_CENTREE, @OPTI_FOURCHE)
			SET @v_delta = CASE @v_chg_position WHEN @OPTI_CENTREE THEN (@v_tag_fourche - @v_longueur) / 2
				WHEN @OPTI_FOURCHE THEN @v_tag_fourche - @v_longueur END
		ELSE
			SET @v_delta = 0
		IF ISNULL(@v_accesbase, 0) = 0
			SET @v_chg_positionprofondeur = @v_chg_positionprofondeur + @v_delta
		ELSE
			SET @v_chg_positionprofondeur = @v_chg_positionprofondeur - @v_longueur - @v_delta
	END	
	IF @v_bas_gerbage = 1
		SET @v_couche = 1
	ELSE
		SELECT @v_couche = STR_COUCHE FROM STRUCTURE WHERE STR_SYSTEME = @v_adr_idsysteme
			AND STR_BASE = @v_adr_idbase AND STR_SOUSBASE = @v_adr_idsousbase AND STR_COTE = @v_chg_positionniveau
	IF @v_bas_gerbage = 0
		SELECT @v_rang = ISNULL(CASE WHEN ISNULL(@v_accesbase, 0) = 0 THEN MAX(CHG_RANG) + 1 ELSE MIN(CHG_RANG) - 1 END, 1) FROM INT_CHARGE_VIVANTE WHERE CHG_IDSYSTEME = @v_adr_idsysteme
			AND CHG_IDBASE = @v_adr_idbase AND CHG_IDSOUSBASE = @v_adr_idsousbase AND CHG_COUCHE = @v_couche
	ELSE
	BEGIN
		IF EXISTS (SELECT 1 FROM INT_CHARGE_VIVANTE WHERE CHG_IDSYSTEME = @v_adr_idsysteme AND CHG_IDBASE = @v_adr_idbase
			AND CHG_IDSOUSBASE = @v_adr_idsousbase AND CHG_COUCHE = @v_couche)
			SELECT TOP 1 @v_rang = CASE WHEN ISNULL(@v_accesbase, 0) = 0 THEN MAX(CHG_RANG) ELSE MIN(CHG_RANG) END
				+ CASE WHEN ISNULL(@v_accesbase, 0) = 0 THEN 1 ELSE -1 END * CASE WHEN @v_chg_positionniveau = 0 THEN 1 ELSE 0 END
				FROM INT_CHARGE_VIVANTE WHERE CHG_IDSYSTEME = @v_adr_idsysteme
				AND CHG_IDBASE = @v_adr_idbase AND CHG_IDSOUSBASE = @v_adr_idsousbase AND CHG_COUCHE = @v_couche
		ELSE
			SET @v_rang = 1
	END

	INSERT INTO @positioncharge SELECT @v_chg_positionprofondeur, @v_chg_positionniveau, @v_couche, @v_rang
	RETURN
END

