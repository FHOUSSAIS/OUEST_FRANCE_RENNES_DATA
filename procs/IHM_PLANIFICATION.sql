SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: IHM_PLANIFICATION
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_ssaction : Sous action à mener
--			  @v_pla_id : Identification
--			  @v_pla_mode_exploitation : Identifiant mode exploitation
--			  @v_pla_info_agv : Identifiant AGV
--			  @v_pla_actif : Actif
--			  @v_pla_jour_debut : Jour de début
--			  @v_pla_heure_debut :  : Heure de début
--			  @v_pla_jour_fin :  : Jour de fin
--			  @v_pla_heure_fin : Heure de fin
-- Paramètre de sorties	: @v_retour : Code de retour
-- Descriptif		: Gestion de la planification des modes d'exploitations
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[IHM_PLANIFICATION]
	@v_action smallint,
	@v_ssaction smallint,
	@v_pla_id int,
	@v_pla_mode_exploitation int,
	@v_pla_info_agv tinyint,
	@v_pla_actif bit,
	@v_pla_jour_debut int,
	@v_pla_heure_debut int,
	@v_pla_jour_fin int,
	@v_pla_heure_fin int,
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error smallint,
	@v_count int,
	@v_hour int,
	@v_min int,
	@v_pla_before int,
	@v_pla_before_mode_exploitation int,
	@v_pla_after int,
	@v_pla_after_mode_exploitation int,
	@v_pla_after_jour_fin int,
	@v_pla_after_heure_fin int,
	@v_pla_next int,
	@v_pla_next_mode_exploitation int,
	@v_pla_next_jour_debut int,
	@v_pla_next_heure_debut int,
	@v_pla_previous_mode_exploitation int,
	@v_pla_old_jour_debut int,
	@v_pla_old_heure_debut int,
	@v_pla_old_jour_fin int,
	@v_pla_old_heure_fin int

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM PLANIFICATION WHERE (PLA_INFO_AGV IS NULL AND @v_pla_info_agv IS NULL)
			OR (PLA_INFO_AGV = @v_pla_info_agv AND @v_pla_info_agv IS NOT NULL))
		BEGIN
			INSERT INTO PLANIFICATION (PLA_MODE_EXPLOITATION, PLA_INFO_AGV, PLA_ACTIF, PLA_JOUR_DEBUT,
				PLA_HEURE_DEBUT, PLA_JOUR_FIN, PLA_HEURE_FIN) VALUES (@v_pla_mode_exploitation, @v_pla_info_agv, @v_pla_actif,
				1, 0, 7, 1440)
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
		ELSE
		BEGIN
			DELETE PLANIFICATION WHERE ((PLA_INFO_AGV IS NULL AND @v_pla_info_agv IS NULL) OR (PLA_INFO_AGV = @v_pla_info_agv AND @v_pla_info_agv IS NOT NULL))
				AND ((PLA_JOUR_DEBUT > @v_pla_jour_debut) OR (PLA_JOUR_DEBUT = @v_pla_jour_debut AND PLA_HEURE_DEBUT >= @v_pla_heure_debut))
				AND ((PLA_JOUR_FIN < @v_pla_jour_fin) OR (PLA_JOUR_FIN = @v_pla_jour_fin AND PLA_HEURE_FIN <= @v_pla_heure_fin))
			SELECT @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				INSERT INTO PLANIFICATION (PLA_MODE_EXPLOITATION, PLA_INFO_AGV, PLA_ACTIF, PLA_JOUR_DEBUT,
					PLA_HEURE_DEBUT, PLA_JOUR_FIN, PLA_HEURE_FIN) VALUES (@v_pla_mode_exploitation, @v_pla_info_agv, @v_pla_actif,
					@v_pla_jour_debut, @v_pla_heure_debut, @v_pla_jour_fin, @v_pla_heure_fin)
				SELECT @v_error = @@ERROR
				SELECT @v_pla_id = SCOPE_IDENTITY()
				SELECT TOP 1 @v_pla_before = PLA_ID, @v_pla_before_mode_exploitation = PLA_MODE_EXPLOITATION FROM PLANIFICATION
					WHERE ((PLA_INFO_AGV IS NULL AND @v_pla_info_agv IS NULL) OR (PLA_INFO_AGV = @v_pla_info_agv AND @v_pla_info_agv IS NOT NULL))
					AND ((PLA_JOUR_DEBUT < @v_pla_jour_debut) OR (PLA_JOUR_DEBUT = @v_pla_jour_debut AND PLA_HEURE_DEBUT <= @v_pla_heure_debut))
					AND PLA_ID <> @v_pla_id ORDER BY PLA_JOUR_DEBUT DESC, PLA_HEURE_DEBUT DESC
				IF ((@v_error = 0) AND (@v_pla_before IS NULL))
				BEGIN
					INSERT INTO PLANIFICATION (PLA_MODE_EXPLOITATION, PLA_INFO_AGV, PLA_ACTIF, PLA_JOUR_DEBUT,
						PLA_HEURE_DEBUT, PLA_JOUR_FIN, PLA_HEURE_FIN) SELECT TOP 1 PLA_MODE_EXPLOITATION, @v_pla_info_agv, @v_pla_actif,
						1, 0, @v_pla_jour_debut, @v_pla_heure_debut FROM PLANIFICATION
						ORDER BY PLA_JOUR_FIN DESC, PLA_HEURE_FIN DESC
					SELECT @v_error = @@ERROR
					SELECT @v_pla_before = SCOPE_IDENTITY()
					SELECT @v_pla_before_mode_exploitation = PLA_MODE_EXPLOITATION FROM PLANIFICATION WHERE PLA_ID = @v_pla_before
				END
				SELECT TOP 1 @v_pla_after = PLA_ID, @v_pla_after_mode_exploitation = PLA_MODE_EXPLOITATION,
					@v_pla_after_jour_fin = PLA_JOUR_FIN, @v_pla_after_heure_fin = PLA_HEURE_FIN FROM PLANIFICATION
					WHERE ((PLA_INFO_AGV IS NULL AND @v_pla_info_agv IS NULL) OR (PLA_INFO_AGV = @v_pla_info_agv AND @v_pla_info_agv IS NOT NULL))
					AND ((PLA_JOUR_FIN > @v_pla_jour_fin) OR (PLA_JOUR_FIN = @v_pla_jour_fin AND PLA_HEURE_FIN >= @v_pla_heure_fin))
					AND PLA_ID <> @v_pla_id ORDER BY PLA_JOUR_FIN, PLA_HEURE_FIN
				IF ((@v_error = 0) AND ((@v_pla_after IS NULL) OR (@v_pla_before = @v_pla_after)))
				BEGIN
					IF @v_pla_after IS NULL
						INSERT INTO PLANIFICATION (PLA_MODE_EXPLOITATION, PLA_INFO_AGV, PLA_ACTIF, PLA_JOUR_DEBUT,
							PLA_HEURE_DEBUT, PLA_JOUR_FIN, PLA_HEURE_FIN) SELECT TOP 1 PLA_MODE_EXPLOITATION, @v_pla_info_agv, @v_pla_actif,
							@v_pla_jour_fin, @v_pla_heure_fin, 7, 1440 FROM PLANIFICATION
							ORDER BY PLA_JOUR_DEBUT, PLA_HEURE_DEBUT
					ELSE	
						INSERT INTO PLANIFICATION (PLA_MODE_EXPLOITATION, PLA_INFO_AGV, PLA_ACTIF, PLA_JOUR_DEBUT,
							PLA_HEURE_DEBUT, PLA_JOUR_FIN, PLA_HEURE_FIN) SELECT PLA_MODE_EXPLOITATION, PLA_INFO_AGV, PLA_ACTIF,
							@v_pla_jour_fin, @v_pla_heure_fin, PLA_JOUR_FIN, PLA_HEURE_FIN FROM PLANIFICATION WHERE PLA_ID = @v_pla_before
					SELECT @v_error = @@ERROR
					SELECT @v_pla_after = SCOPE_IDENTITY()
					SELECT @v_pla_after_jour_fin = PLA_JOUR_FIN, @v_pla_after_heure_fin = PLA_HEURE_FIN,
						@v_pla_after_mode_exploitation = PLA_MODE_EXPLOITATION FROM PLANIFICATION WHERE PLA_ID = @v_pla_after
				END
				IF @v_error = 0
				BEGIN
					IF ((@v_pla_mode_exploitation = @v_pla_before_mode_exploitation) AND (@v_pla_mode_exploitation = @v_pla_after_mode_exploitation))
					BEGIN
						UPDATE PLANIFICATION SET PLA_JOUR_FIN = @v_pla_after_jour_fin, PLA_HEURE_FIN = @v_pla_after_heure_fin
							WHERE PLA_ID = @v_pla_before
						SELECT @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							DELETE PLANIFICATION WHERE PLA_ID = @v_pla_id
							SELECT @v_error = @@ERROR
							IF @v_error = 0
							BEGIN
								DELETE PLANIFICATION WHERE PLA_ID = @v_pla_after
								SELECT @v_error = @@ERROR
							END
						END
					END
					ELSE IF @v_pla_mode_exploitation = @v_pla_before_mode_exploitation
					BEGIN
						UPDATE PLANIFICATION SET PLA_JOUR_FIN = @v_pla_jour_fin, PLA_HEURE_FIN = @v_pla_heure_fin
							WHERE PLA_ID = @v_pla_before
						SELECT @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							UPDATE PLANIFICATION SET PLA_JOUR_DEBUT = @v_pla_jour_fin, PLA_HEURE_DEBUT = @v_pla_heure_fin
								WHERE PLA_ID = @v_pla_after
							SELECT @v_error = @@ERROR
							IF @v_error = 0
							BEGIN
								DELETE PLANIFICATION WHERE PLA_ID = @v_pla_id
								SELECT @v_error = @@ERROR
							END
						END
					END
					ELSE IF @v_pla_mode_exploitation = @v_pla_after_mode_exploitation
					BEGIN
						UPDATE PLANIFICATION SET PLA_JOUR_FIN = @v_pla_jour_debut, PLA_HEURE_FIN = @v_pla_heure_debut
							WHERE PLA_ID = @v_pla_before
						SELECT @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							UPDATE PLANIFICATION SET PLA_JOUR_DEBUT = @v_pla_jour_debut, PLA_HEURE_DEBUT = @v_pla_heure_debut
								WHERE PLA_ID = @v_pla_after
							SELECT @v_error = @@ERROR
							IF @v_error = 0
							BEGIN
								DELETE PLANIFICATION WHERE PLA_ID = @v_pla_id
								SELECT @v_error = @@ERROR
							END
						END
					END
					ELSE
					BEGIN
						UPDATE PLANIFICATION SET PLA_JOUR_FIN = @v_pla_jour_debut, PLA_HEURE_FIN = @v_pla_heure_debut
							WHERE PLA_ID = @v_pla_before
						SELECT @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							UPDATE PLANIFICATION SET PLA_JOUR_DEBUT = @v_pla_jour_fin, PLA_HEURE_DEBUT = @v_pla_heure_fin
								WHERE PLA_ID = @v_pla_after
							SELECT @v_error = @@ERROR
							IF @v_error = 0
							BEGIN
								UPDATE PLANIFICATION SET PLA_JOUR_DEBUT = @v_pla_jour_debut, PLA_HEURE_DEBUT = @v_pla_heure_debut,
									PLA_JOUR_FIN = @v_pla_jour_fin, PLA_HEURE_FIN = @v_pla_heure_fin
									WHERE PLA_ID = @v_pla_id
								SELECT @v_error = @@ERROR
							END
						END
					END
				END
				IF @v_error = 0
				BEGIN
					DELETE PLANIFICATION WHERE ((PLA_INFO_AGV IS NULL AND @v_pla_info_agv IS NULL) OR (PLA_INFO_AGV = @v_pla_info_agv AND @v_pla_info_agv IS NOT NULL))
						AND PLA_JOUR_DEBUT = PLA_JOUR_FIN AND PLA_HEURE_DEBUT = PLA_HEURE_FIN
					SELECT @v_error = @@ERROR
					IF @v_error = 0
						SELECT @v_retour = 0
				END
			END
		END
	END
	ELSE IF @v_action = 1
	BEGIN
		IF @v_ssaction = 0
		BEGIN
			UPDATE PLANIFICATION SET PLA_ACTIF = @v_pla_actif WHERE PLA_ID = @v_pla_id
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = 0
		END
		ELSE IF @v_ssaction = 1
		BEGIN
			SELECT @v_pla_old_jour_debut = PLA_JOUR_DEBUT, @v_pla_old_heure_debut = PLA_HEURE_DEBUT,
				@v_pla_old_jour_fin = PLA_JOUR_FIN, @v_pla_old_heure_fin = PLA_HEURE_FIN FROM PLANIFICATION
				WHERE PLA_ID = @v_pla_id
			EXEC @v_error = IHM_PLANIFICATION 2, NULL, @v_pla_id, NULL, @v_pla_info_agv, NULL,
				@v_pla_old_jour_debut, @v_pla_old_heure_debut, @v_pla_old_jour_fin, @v_pla_old_heure_fin, @v_retour out
			IF ((@v_error = 0) AND (@v_retour = 0))
			BEGIN
				EXEC @v_error = IHM_PLANIFICATION 0, NULL, NULL, @v_pla_mode_exploitation, @v_pla_info_agv, @v_pla_actif,
					@v_pla_jour_debut, @v_pla_heure_debut, @v_pla_jour_fin, @v_pla_heure_fin, @v_retour out
			END
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		DELETE PLANIFICATION WHERE PLA_ID = @v_pla_id
		SELECT @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			SELECT @v_count = COUNT(*) FROM PLANIFICATION WHERE (PLA_INFO_AGV IS NULL AND @v_pla_info_agv IS NULL) OR (PLA_INFO_AGV = @v_pla_info_agv AND @v_pla_info_agv IS NOT NULL)
			IF @v_count = 1
			BEGIN
				UPDATE PLANIFICATION SET PLA_JOUR_DEBUT = 1, PLA_HEURE_DEBUT = 0, PLA_JOUR_FIN = 7,
					PLA_HEURE_FIN = 1440 WHERE (PLA_INFO_AGV IS NULL AND @v_pla_info_agv IS NULL) OR (PLA_INFO_AGV = @v_pla_info_agv AND @v_pla_info_agv IS NOT NULL)
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
			ELSE IF @v_count <> 0
			BEGIN
				SELECT TOP 1 @v_pla_before = PLA_ID, @v_pla_before_mode_exploitation = PLA_MODE_EXPLOITATION FROM PLANIFICATION
					WHERE ((PLA_INFO_AGV IS NULL AND @v_pla_info_agv IS NULL) OR (PLA_INFO_AGV = @v_pla_info_agv AND @v_pla_info_agv IS NOT NULL))
					AND ((PLA_JOUR_FIN < @v_pla_jour_debut) OR (PLA_JOUR_FIN = @v_pla_jour_debut AND PLA_HEURE_FIN <= @v_pla_heure_debut))
					ORDER BY PLA_JOUR_DEBUT DESC, PLA_HEURE_DEBUT DESC
				SELECT TOP 1 @v_pla_after = PLA_ID, @v_pla_after_mode_exploitation = PLA_MODE_EXPLOITATION,
					@v_pla_after_jour_fin = PLA_JOUR_FIN, @v_pla_after_heure_fin = PLA_HEURE_FIN FROM PLANIFICATION
					WHERE ((PLA_INFO_AGV IS NULL AND @v_pla_info_agv IS NULL) OR (PLA_INFO_AGV = @v_pla_info_agv AND @v_pla_info_agv IS NOT NULL))
					AND ((PLA_JOUR_DEBUT > @v_pla_jour_fin) OR (PLA_JOUR_DEBUT = @v_pla_jour_fin AND PLA_HEURE_DEBUT >= @v_pla_heure_fin))
					ORDER BY PLA_JOUR_FIN, PLA_HEURE_FIN
				IF @v_pla_before IS NULL
				BEGIN
					UPDATE PLANIFICATION SET PLA_JOUR_DEBUT = 1, PLA_HEURE_DEBUT = 0
						WHERE PLA_ID = @v_pla_after
					SELECT @v_error = @@ERROR
				END
				ELSE IF @v_pla_after IS NULL
				BEGIN
					UPDATE PLANIFICATION SET PLA_JOUR_FIN = 7, PLA_HEURE_FIN = 1440
						WHERE PLA_ID = @v_pla_before
					SELECT @v_error = @@ERROR
				END
				ELSE IF @v_pla_before_mode_exploitation = @v_pla_after_mode_exploitation
				BEGIN
					UPDATE PLANIFICATION SET PLA_JOUR_FIN = @v_pla_after_jour_fin, PLA_HEURE_FIN = @v_pla_after_heure_fin
						WHERE PLA_ID = @v_pla_before
					SELECT @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						DELETE PLANIFICATION WHERE PLA_ID = @v_pla_after
						SELECT @v_error = @@ERROR
					END
				END
				ELSE
				BEGIN
					UPDATE PLANIFICATION SET PLA_JOUR_FIN = @v_pla_jour_fin, PLA_HEURE_FIN = @v_pla_heure_fin
						WHERE PLA_ID = @v_pla_before
					SELECT @v_error = @@ERROR
				END
				IF @v_error = 0
					SELECT @v_retour = 0
			END
			ELSE
				SELECT @v_retour = 0
		END
	END
	ELSE IF @v_action = 3
	BEGIN
		DELETE PLANIFICATION
		SELECT @v_error = @@ERROR
		IF @v_error = 0
			SELECT @v_retour = 0
	END
	IF ((@v_error = 0) AND NOT ((@v_action = 1) AND (@v_ssaction = 0)))
	BEGIN
		IF EXISTS (SELECT COUNT(*) FROM PLANIFICATION HAVING COUNT(*) > 1)
		BEGIN
			DECLARE c_planification CURSOR LOCAL FOR SELECT PLA_ID, PLA_MODE_EXPLOITATION, PLA_JOUR_DEBUT, PLA_HEURE_DEBUT
				FROM PLANIFICATION WHERE PLA_ACTIF = 1 FOR UPDATE
			OPEN c_planification
			FETCH NEXT FROM c_planification INTO @v_pla_next, @v_pla_next_mode_exploitation, @v_pla_next_jour_debut, @v_pla_next_heure_debut
			WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
			BEGIN
				IF ((@v_pla_next_jour_debut = 1) AND (@v_pla_next_heure_debut = 0))
				BEGIN
					SELECT TOP 1 @v_pla_previous_mode_exploitation = PLA_MODE_EXPLOITATION FROM PLANIFICATION WHERE PLA_ID <> @v_pla_next
						ORDER BY PLA_JOUR_FIN DESC, PLA_HEURE_FIN DESC
					IF @v_pla_previous_mode_exploitation = @v_pla_next_mode_exploitation
					BEGIN			
						UPDATE PLANIFICATION SET PLA_PROCHAINE_EXECUTION = NULL WHERE CURRENT OF c_planification
						SELECT @v_error = @@ERROR
						FETCH NEXT FROM c_planification INTO @v_pla_next, @v_pla_next_mode_exploitation, @v_pla_next_jour_debut, @v_pla_next_heure_debut
						CONTINUE
					END
				END
				IF @v_pla_next_jour_debut = ((@@DATEFIRST + DATEPART(dw, GETDATE()) - 2) % 7) + 1
				BEGIN
					SELECT @v_hour = @v_pla_next_heure_debut / 60
					SELECT @v_min = @v_pla_next_heure_debut - @v_hour * 60
					IF ((CONVERT(varchar(8), GETDATE(), 108)) > (CONVERT (varchar(2), @v_hour) + ':' + CONVERT (varchar(2), @v_min)))
					BEGIN
						UPDATE PLANIFICATION SET PLA_PROCHAINE_EXECUTION = CONVERT(datetime, CONVERT(varchar(8), DATEADD(d, 7, GETDATE()), 112)
							+ ' ' + CONVERT (varchar(2), @v_hour) + ':' + CONVERT (varchar(2), @v_min))
							WHERE CURRENT OF c_planification
						SELECT @v_error = @@ERROR
					END
					ELSE
					BEGIN
						UPDATE PLANIFICATION SET PLA_PROCHAINE_EXECUTION = CONVERT(datetime, CONVERT(varchar(8), GETDATE(), 112)
							+ ' ' + CONVERT (varchar(2), @v_hour) + ':' + CONVERT (varchar(2), @v_min))
							WHERE CURRENT OF c_planification
						SELECT @v_error = @@ERROR
					END
				END
				ELSE
				BEGIN
					SELECT @v_hour = @v_pla_next_heure_debut / 60
					SELECT @v_min = @v_pla_next_heure_debut - @v_hour * 60
					UPDATE PLANIFICATION SET PLA_PROCHAINE_EXECUTION = CONVERT(datetime, CONVERT(varchar(8), DATEADD(d, PLA_JOUR_DEBUT - (((@@DATEFIRST + DATEPART(dw, GETDATE()) - 2) % 7) + 1), GETDATE()), 112)
						+ ' ' + CONVERT (varchar(2), @v_hour) + ':' + CONVERT (varchar(2), @v_min))
						WHERE CURRENT OF c_planification
					SELECT @v_error = @@ERROR
				END
				FETCH NEXT FROM c_planification INTO @v_pla_next, @v_pla_next_mode_exploitation, @v_pla_next_jour_debut, @v_pla_next_heure_debut
			END
			CLOSE c_planification
			DEALLOCATE c_planification
		END
		ELSE
			UPDATE PLANIFICATION SET PLA_PROCHAINE_EXECUTION = NULL
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error


